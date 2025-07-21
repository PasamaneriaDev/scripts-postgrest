-- Crear la tabla ordenes_rollos_detalle
-- drop table if exists trabajo_proceso.ordenes_rollos_detalle;
CREATE TABLE trabajo_proceso.ordenes_rollos_detalle
(
    codigo_orden                 VARCHAR(15) NOT NULL,
    numero_rollo                 VARCHAR(3)  NOT NULL,
    peso_crudo                   NUMERIC(13, 3) DEFAULT 0,
    tonalidad                    VARCHAR(50)    DEFAULT NULL,
    creacion_usuario             VARCHAR(50),
    creacion_fecha               date           DEFAULT CURRENT_DATE,
    creacion_hora                TIME           DEFAULT CURRENT_TIME,

    operario_registro_produccion VARCHAR(50),
    fecha_registro_produccion    TIMESTAMP,
    codigo_orden_hilo            VARCHAR(15)    DEFAULT NULL,

    usuario_pesa_crudo           varchar(4),
    fecha_pesado_crudo           timestamp,
    observacion_pesa_crudo       VARCHAR(150)   DEFAULT NULL,
    reubicado_bodega_crudos      boolean        DEFAULT FALSE,
    CONSTRAINT ordenes_rollos_detalle_pk PRIMARY KEY (codigo_orden, numero_rollo)
);

ALTER TABLE trabajo_proceso.ordenes_rollos_detalle
    ADD COLUMN;

-- Crear la función para generar el siguiente numero_rollo
CREATE OR REPLACE FUNCTION trabajo_proceso.generar_numero_rollo(p_codigo_orden VARCHAR)
    RETURNS VARCHAR AS
$$
DECLARE
    v_ultimo_numero INTEGER;
    v_nuevo_numero  VARCHAR(3);
BEGIN
    -- Obtener el último número usado para el codigo_orden
    SELECT COALESCE(MAX(CAST(numero_rollo AS INTEGER)), 0)
    INTO v_ultimo_numero
    FROM trabajo_proceso.ordenes_rollos_detalle
    WHERE codigo_orden = p_codigo_orden;

    -- Incrementar el número y formatear con ceros a la izquierda
    v_nuevo_numero := LPAD((v_ultimo_numero + 1)::TEXT, 3, '0');

    -- Verificar que no exceda 999
    IF v_nuevo_numero::INTEGER > 999 THEN
        RAISE EXCEPTION 'El número de rollo ha alcanzado el límite máximo (999) para el código de orden %', p_codigo_orden;
    END IF;

    RETURN v_nuevo_numero;
END;
$$ LANGUAGE plpgsql;

-- Crear la función para el trigger
CREATE OR REPLACE FUNCTION trabajo_proceso.asignar_numero_rollo()
    RETURNS TRIGGER AS
$$
BEGIN
    NEW.numero_rollo := trabajo_proceso.generar_numero_rollo(NEW.codigo_orden);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trigger_asignar_numero_rollo
    BEFORE INSERT
    ON trabajo_proceso.ordenes_rollos_detalle
    FOR EACH ROW
EXECUTE FUNCTION trabajo_proceso.asignar_numero_rollo();




