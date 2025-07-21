-- DROP FUNCTION public.cierre();

CREATE OR REPLACE FUNCTION public.cierre()
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _fecha_hora_inicial TIMESTAMP WITH TIME ZONE;
    _fecha_hora_final   TIMESTAMP WITH TIME ZONE;
    _tiempo             DECIMAL;
    _numero_email       NUMERIC;
    _msgerrror1         text;
    _msgerrror2         text;
    _msgerrror3         text;
    _secuencia          INTEGER;

BEGIN

    _fecha_hora_inicial = CLOCK_TIMESTAMP();
    INSERT INTO sistema.bitacora
        (computador, usuario, fecha_inicial, hora_inicial, modulo)
    VALUES ('LINUX', 'ADMN', _fecha_hora_inicial::DATE,
            LEFT((_fecha_hora_inicial::time WITHOUT TIME ZONE)::VARCHAR, 10), 'CIERRE MENSUAL')
    RETURNING secuencia INTO _secuencia;


    IF DATE_PART('MONTH', CURRENT_DATE - 1) < 12 THEN
        --Cuenta por cobrar
        UPDATE cuentas_cobrar.clientes
        SET ventas_periodo      = 0,
            dias_plazo_anterior = dias_plazo,
            banderas            = SUBSTRING(banderas FROM 1 FOR 8) || 'N' || SUBSTRING(banderas FROM 10);

        --Proveedores
        UPDATE cuentas_pagar.proveedores
        SET compras_periodo = 0
        WHERE compras_periodo <> 0;

        --Items
        WITH t
                 AS
                 (SELECT item, nivel_materia_prima + acumulacion_materia_prima AS costo
                  FROM costos.costos
                  WHERE tipo_costo = 'Standard')
        UPDATE control_inventarios.items
        SET valor_vendido_periodo     = 0,
            valor_usado_periodo       = 0,
            cantidad_usada_periodo    = 0,
            cantidad_vendida_periodo  = 0,
            cantidad_recibida_periodo = 0,
            valor_recibido_periodo    = 0,
            costo_totalmente_variable = t.costo
        FROM t
        WHERE items.item = t.item;

        --Bodegas
        UPDATE control_inventarios.bodegas
        SET cantidad_vendida_periodo  = 0,
            valor_vendido_periodo     = 0,
            cantidad_recibida_periodo = 0,
            valor_recibido_periodo    = 0,
            cantidad_usada_periodo    = 0,
            valor_usado_periodo       = 0
        WHERE cantidad_vendida_periodo <> 0
           OR valor_vendido_periodo <> 0
           OR cantidad_recibida_periodo <> 0
           OR valor_recibido_periodo <> 0
           OR cantidad_usada_periodo <> 0
           OR valor_usado_periodo <> 0;

    ELSE
        --Cuenta por cobrar
        UPDATE cuentas_cobrar.clientes
        SET ventas_periodo      = 0,
            dias_plazo_anterior = dias_plazo,
            banderas            = SUBSTRING(banderas FROM 1 FOR 8) || 'N' || SUBSTRING(banderas FROM 10),
            ventas_anio         = 0;

        --Proveedores
        UPDATE cuentas_pagar.proveedores
        SET compras_periodo = 0,
            compras_ano     = 0,
            pagos_ano       = 0;

        --Items
        WITH t
                 AS
                 (SELECT item, nivel_materia_prima + acumulacion_materia_prima AS costo
                  FROM costos.costos
                  WHERE tipo_costo = 'Standard')
        UPDATE control_inventarios.items
        SET valor_vendido_periodo     = 0,
            valor_usado_periodo       = 0,
            cantidad_usada_periodo    = 0,
            cantidad_vendida_periodo  = 0,
            cantidad_recibida_periodo = 0,
            valor_recibido_periodo    = 0,
            costo_totalmente_variable = t.costo,
            valor_usado_ano           = 0,
            valor_vendido_ano         = 0,
            cantidad_usada_ano        = 0,
            cantidad_vendida_ano      = 0,
            valor_recibido_ano        = 0,
            cantidad_recibida_ano     = 0
        FROM t
        WHERE items.item = t.item;

        --Bodegas
        UPDATE control_inventarios.bodegas
        SET cantidad_vendida_periodo  = 0,
            valor_vendido_periodo     = 0,
            cantidad_recibida_periodo = 0,
            valor_recibido_periodo    = 0,
            cantidad_usada_periodo    = 0,
            valor_usado_periodo       = 0,
            cantidad_vendida_ano      = 0,
            valor_vendido_ano         = 0,
            valor_recibido_ano        = 0,
            cantidad_recibida_ano     = 0,
            cantidad_usada_ano        = 0,
            valor_usado_ano           = 0
        WHERE cantidad_vendida_periodo <> 0
           OR valor_vendido_periodo <> 0
           OR cantidad_recibida_periodo <> 0
           OR valor_recibido_periodo <> 0
           OR cantidad_usada_periodo <> 0
           OR valor_usado_periodo <> 0
           OR cantidad_vendida_ano <> 0
           OR valor_vendido_ano <> 0
           OR valor_recibido_ano <> 0
           OR cantidad_recibida_ano <> 0
           OR cantidad_usada_ano <> 0
           OR valor_usado_ano <> 0;


        --Items Proveedores
        UPDATE control_inventarios.items_proveedores
        SET cantidad_recibida_anio = 0
        WHERE cantidad_recibida_anio <> 0;

        --Personal
        UPDATE roles.personal
        SET almacen_uso = 0
        WHERE almacen_uso <> 0;

    END IF;

    UPDATE trabajo_proceso.ordenes o
    SET cantidad_planificada = 0
      , cantidad_fabricada   = 0
    WHERE LEFT(o.codigo_orden, 4) = ANY ('{4H-4,7M-7}'::TEXT[])
      AND ABS(o.cantidad_planificada) + ABS(o.cantidad_fabricada) <> 0;


    _fecha_hora_final = CLOCK_TIMESTAMP();
    SELECT (EXTRACT(HOUR FROM t.tiempo) * 60) + EXTRACT(MINUTE FROM t.tiempo)
    INTO _tiempo
    FROM (VALUES (_fecha_hora_final - _fecha_hora_inicial)) t (tiempo);

    UPDATE sistema.bitacora
    SET fecha_final  = _fecha_hora_final::DATE,
        hora_final   = LEFT((_fecha_hora_final::time WITHOUT TIME ZONE)::VARCHAR, 10),
        tiempo_total = _tiempo
    WHERE secuencia = _secuencia;

    -- JG: 20250717, Corte de Cierre Mensual para Producto en Proceso
    PERFORM auditoria.corte_producto_proceso_cierre_mes();

    INSERT INTO sistema.control_tareas_programadas(tarea_ejecutada, estado) VALUES ('CIERRE MENSUAL', 'PROCESADO');

    --Envia mail de que todo termino correctamente.
    SELECT MAX(t1.numero_email) + 1 INTO _numero_email FROM sistema.email_masivo_cabecera t1;

    INSERT INTO sistema.email_masivo_cabecera
    (numero_email, fecha, asunto_email, mensaje_email, imagen_email_cabecera, nombre_empresa, estado)
    VALUES (_numero_email, CURRENT_DATE, 'Tareas Programadas Linux - CIERRE MENSUAL exitoso', 'Saludos cordiales,', '',
            'Pasamanería S.A.', 'P');

    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (_numero_email, 'lorena.washima@pasa.ec,alicia.gualpa@pasa.ec', 'Lorena Washima');

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS _msgerrror1 = MESSAGE_TEXT,
            _msgerrror2 = PG_EXCEPTION_DETAIL,
            _msgerrror3 = PG_EXCEPTION_HINT;
        INSERT INTO sistema.control_tareas_programadas(tarea_ejecutada, estado)
        VALUES ('CIERRE MENSUAL', 'ERROR ' || msgerrror1 || ' ' || msgerrror2 || ' ' || msgerrror3);

END
$function$
;
