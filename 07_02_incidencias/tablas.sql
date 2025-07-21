-- Step 1: Create the new table
-- drop table puntos_venta.incidencias_estados
CREATE TABLE puntos_venta.incidencias_estados
(
    secuencia         SERIAL PRIMARY KEY,
    numero_incidencia INTEGER NOT NULL,
    estado            VARCHAR(20),
    usuario           VARCHAR(4),
    fecha             TIMESTAMP,
    observacion       VARCHAR(400),
    FOREIGN KEY (numero_incidencia) REFERENCES puntos_venta.incidencias (numero_incidencia)
);

-- Step 2: Insert existing data into the new table
INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha, observacion)
SELECT numero_incidencia, 'EN TRAMITE', creacion_usuario, creacion_fecha, NULL
FROM puntos_venta.incidencias
UNION ALL
SELECT numero_incidencia, 'AUTORIZADO', autorizacion_usuario, autorizacion_fecha, NULL
FROM puntos_venta.incidencias
WHERE autorizacion_usuario IS NOT NULL
UNION ALL
SELECT numero_incidencia, 'COMPLETO', finalizacion_usuario, finalizacion_fecha, NULL
FROM puntos_venta.incidencias
WHERE finalizacion_usuario IS NOT NULL
UNION ALL
SELECT numero_incidencia, 'NO AUTORIZADO', noautorizado_usuario, noautorizado_fecha, observacion_noautorizado
FROM puntos_venta.incidencias
WHERE noautorizado_usuario IS NOT NULL
UNION ALL
SELECT numero_incidencia, 'EN EJECUCION', ejecucion_usuario, ejecucion_fecha, NULL
FROM puntos_venta.incidencias
WHERE ejecucion_usuario IS NOT NULL
  AND ejecucion_fecha IS NOT NULL
UNION ALL
SELECT numero_incidencia, 'NO EJECUTADO', noejecutado_usuario, noejecutado_fecha, observacion_noejecutado
FROM puntos_venta.incidencias
WHERE noejecutado_usuario IS NOT NULL;


TRUNCATE TABLE puntos_venta.incidencias_estados

-- Step 3: Update the incidencias table
ALTER TABLE puntos_venta.incidencias
    DROP COLUMN creacion_usuario,
    DROP COLUMN creacion_fecha,
    DROP COLUMN autorizacion_usuario,
    DROP COLUMN autorizacion_fecha,
    DROP COLUMN finalizacion_usuario,
    DROP COLUMN finalizacion_fecha,
    DROP COLUMN noautorizado_usuario,
    DROP COLUMN noautorizado_fecha,
    DROP COLUMN observacion_noautorizado,
    DROP COLUMN ejecucion_fecha,
    DROP COLUMN noejecutado_usuario,
    DROP COLUMN noejecutado_fecha,
    DROP COLUMN observacion_noejecutado;

DROP TRIGGER trg_actualizar_estado ON puntos_venta.incidencias;
drop FUNCTION puntos_venta.incidencias_actualizar_estado;



-- Crear la función que será llamada por el trigger
CREATE OR REPLACE FUNCTION actualizar_estado_incidencia()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE puntos_venta.incidencias
    SET estado = NEW.estado
    WHERE numero_incidencia = NEW.numero_incidencia;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger que llama a la función anterior
CREATE TRIGGER trg_actualizar_estado
AFTER INSERT ON puntos_venta.incidencias_estados
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado_incidencia();