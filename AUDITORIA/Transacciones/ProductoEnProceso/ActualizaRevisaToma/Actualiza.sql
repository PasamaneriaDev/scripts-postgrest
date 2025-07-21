-- drop FUNCTION auditoria.inventario_proceso_actualiza(p_papeleta_inicial varchar)

CREATE OR REPLACE FUNCTION auditoria.inventario_proceso_actualiza(p_papeleta_inicial varchar, p_creacion_usuario varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_cuenta_inventario varchar;
    count               integer;
BEGIN
    -- Encerando Tablas
    TRUNCATE inventario_proceso.ajustes;
    TRUNCATE inventario_proceso.transacciones;
    TRUNCATE inventario_proceso.distribucion;
    DELETE
    FROM sistema.secuencia_diaria
    WHERE secuencia_diaria_id = 'TRANSACCIONES_INVENTARIO_PROCESO';

    INSERT INTO inventario_proceso.ajustes(documento, item, costo, costo_nuevo, orden, cantidad, conos, tara, cajon,
                                           constante, bodega, ubicacion, fecha, status, tipo, cuenta_ajuste, cuenta,
                                           creacion_fecha, creacion_hora, creacion_usuario, secuencia, cantidad_ajuste,
                                           muestra, anio_trimestre)
    SELECT a.documento,
           a.item,
           a.costo,
           a.costo_nuevo,
           a.orden,
           a.cantidad,
           a.conos,
           a.tara,
           a.cajon,
           a.constante,
           CASE
               WHEN a.bodega = 'P1' THEN COALESCE(im.bodega_code, a.bodega)
               ELSE a.bodega
               END AS bodega,
           CASE
               WHEN a.bodega = 'P1' THEN COALESCE(im.ubicacion_code, a.ubicacion)
               ELSE a.ubicacion
               END AS ubicacion,
           a.fecha,
           a.status,
           a.tipo,
           a.cuenta_ajuste,
           a.cuenta,
           a.creacion_fecha,
           a.creacion_hora,
           a.creacion_usuario,
           a.secuencia,
           a.cantidad_ajuste,
           a.muestra,
           a.anio_trimestre
    FROM control_inventarios.ajustes a
             JOIN control_inventarios.id_bodegas_proceso_view ib
                  ON a.bodega = ib.bodega
             LEFT JOIN (VALUES ('2', 'P2', 'P21'),
                               ('3', 'P3', 'P31'),
                               ('4', 'P4', 'P41'),
                               ('5', 'P5', 'P51'),
                               ('6', 'P6', 'P61'),
                               ('9', 'P9', 'P91'),
                               ('M', 'PG', 'PG1')) AS im (item_prefix, bodega_code, ubicacion_code)
                       ON LEFT(a.item, 1) = im.item_prefix
    WHERE a.documento > p_papeleta_inicial
      AND a.tipo = 'T'
      AND a.status = '';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'NO EXISTE nada pendiente por actualizar... No se puede continuar';
    END IF;

    SELECT COUNT(*) INTO count FROM inventario_proceso.ajustes t;
    RAISE NOTICE 'count: %', count;
    -- Actualiza ajustes Vacios
    UPDATE inventario_proceso.ajustes
    SET status = 'C',
        fecha  = CURRENT_DATE
    WHERE item = 'V';

    -- Actualiza/Crea Bodegas
    INSERT INTO inventario_proceso.bodegas (bodega, item, codigo_integracion, existencia, creacion_usuario)
    SELECT a.bodega, a.item, 'PRT', a.cantidad_ajuste, p_creacion_usuario
    FROM inventario_proceso.ajustes a
    ON CONFLICT (bodega, item)
        DO UPDATE
        SET existencia = inventario_proceso.bodegas.existencia + EXCLUDED.existencia;

    -- Actualiza/Crea Ubicaciones
    INSERT INTO inventario_proceso.ubicaciones (bodega, item, ubicacion, existencia, creacion_usuario)
    SELECT a.bodega, a.item, a.ubicacion, a.cantidad_ajuste, p_creacion_usuario
    FROM inventario_proceso.ajustes a
    ON CONFLICT (item, bodega, ubicacion)
        DO UPDATE
        SET existencia = inventario_proceso.ubicaciones.existencia + EXCLUDED.existencia;

    -- Actualiza Existencia Total
    UPDATE inventario_proceso.items AS i
    SET existencia = sr1.total_existencia
    FROM (SELECT u.item, SUM(u.existencia) AS total_existencia
          FROM inventario_proceso.ubicaciones u
                   JOIN (SELECT DISTINCT item
                         FROM inventario_proceso.ajustes) a ON u.item = a.item
          GROUP BY u.item) AS sr1
    WHERE i.item = sr1.item;

    -- TEMPORAL
    -- DROP TABLE IF EXISTS ajuste_tmp;
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT a.bodega,
           a.item,
           'Toma de Invent. Bodega/Ubic.'                                              AS referencia,
           'AJUS PROC'                                                                 AS tipo,
           CURRENT_DATE                                                                AS fecha,
           a.cantidad_ajuste,
           i.costo_estandar,
           'TP'                                                                        AS modulo,
           a.documento,
           a.ubicacion,
           TO_CHAR(a.creacion_fecha, 'YYYYMM')                                         AS periodo,
           p.precio,
           ib.cuenta_materia_prima,
           ib.cuenta_mano_obra,
           ib.cuenta_gastos_fabricacion,
           cl.valor_materia_prima,
           cl.valor_mano_obra,
           cl.valor_gastos_fabricacion,
           (cl.valor_materia_prima + cl.valor_mano_obra + cl.valor_gastos_fabricacion) AS costo_unitario,
           LPAD(((sistema.secuencia_diaria_get('TRANSACCIONES_INVENTARIO_PROCESO'::text))::character varying)::text,
                10,
                '0'::text)                                                             AS transaccion,
           a.secuencia
    FROM inventario_proceso.ajustes a
             JOIN inventario_proceso.items i ON i.item = a.item
             LEFT JOIN control_inventarios.id_bodegas ib ON ib.bodega = a.bodega
             LEFT JOIN control_inventarios.precios p ON p.item = a.item AND p.tipo = 'PVP'
             LEFT JOIN LATERAL (SELECT (c.mantenimiento_materia_prima + c.nivel_materia_prima +
                                        c.acumulacion_materia_prima)      AS valor_materia_prima,
                                       (c.mantenimiento_mano_obra + c.nivel_mano_obra +
                                        c.acumulacion_mano_obra)          AS valor_mano_obra,
                                       (c.mantenimiento_gastos_fabricacion + c.nivel_gastos_fabricacion +
                                        c.acumulacion_gastos_fabricacion) AS valor_gastos_fabricacion
                                FROM inventario_proceso.costos c
                                WHERE c.item = a.item
                                  AND c.tipo_costo = 'Standard') AS cl ON TRUE;

    SELECT COUNT(*) INTO count FROM ajuste_tmp t;
    RAISE NOTICE 'count: %', count;

    -- Inserta Transacciones de Ajuste
    INSERT INTO inventario_proceso.transacciones (transaccion, bodega, item, referencia, tipo_movimiento, fecha,
                                                  cantidad, costo, modulo, documento, ubicacion, periodo, precio,
                                                  creacion_usuario)
    SELECT a.transaccion,
           a.bodega,
           a.item,
           a.referencia,
           a.tipo,
           a.fecha,
           a.cantidad_ajuste,
           a.costo_estandar,
           a.modulo,
           a.documento,
           a.ubicacion,
           a.periodo,
           a.precio,
           p_creacion_usuario
    FROM ajuste_tmp a;

    -- Cuenta de Ajustes
    SELECT p.alfa
    INTO v_cuenta_inventario
    FROM sistema.parametros p
    WHERE p.codigo = 'CUENTA_AJUSTEPT'
      AND p.modulo_id = 'TRABPROC';

    -- Inserta Distribuciones
    INSERT INTO inventario_proceso.distribucion AS d (cuenta, monto, fecha, transaccion, tipo_transaccion,
                                                      periodo, ano, creacion_usuario)
    SELECT x.cuenta
         , x.monto
         , CURRENT_DATE
         , x.transaccion
         , x.tipo_transaccion
         , TO_CHAR(CURRENT_DATE, 'MM')
         , TO_CHAR(CURRENT_DATE, 'YYYY')
         , p_creacion_usuario
    FROM (SELECT v_cuenta_inventario                         AS cuenta
               , (a.cantidad_ajuste * a.valor_materia_prima) AS monto
               , a.transaccion
               , 'DD'                                        AS tipo_transaccion
               , 1                                           AS orden
          FROM ajuste_tmp a
          UNION ALL
          SELECT a.cuenta_materia_prima                           AS cuenta
               , (a.cantidad_ajuste * a.valor_materia_prima * -1) AS monto
               , a.transaccion
               , 'CC'                                             AS tipo_transaccion
               , 2                                                AS orden
          FROM ajuste_tmp a

          UNION ALL

          SELECT v_cuenta_inventario                     AS cuenta
               , (a.cantidad_ajuste * a.valor_mano_obra) AS monto
               , a.transaccion
               , 'DD'                                    AS tipo_transaccion
               , 3                                       AS orden
          FROM ajuste_tmp a
          UNION ALL
          SELECT a.cuenta_mano_obra                           AS cuenta
               , (a.cantidad_ajuste * a.valor_mano_obra * -1) AS monto
               , a.transaccion
               , 'CC'                                         AS tipo_transaccion
               , 4                                            AS orden
          FROM ajuste_tmp a

          UNION ALL

          SELECT v_cuenta_inventario                              AS cuenta
               , (a.cantidad_ajuste * a.valor_gastos_fabricacion) AS monto
               , a.transaccion
               , 'DD'                                             AS tipo_transaccion
               , 5                                                AS orden
          FROM ajuste_tmp a
          UNION ALL
          SELECT a.cuenta_gastos_fabricacion                           AS cuenta
               , (a.cantidad_ajuste * a.valor_gastos_fabricacion * -1) AS monto
               , a.transaccion
               , 'CC'                                                  AS tipo_transaccion
               , 6                                                     AS orden
          FROM ajuste_tmp a) x
    ORDER BY x.transaccion, x.orden;

    UPDATE inventario_proceso.ajustes a
    SET status = 'C',
        fecha  = CURRENT_DATE
    FROM ajuste_tmp t
    WHERE a.secuencia = t.secuencia;

END;
$function$;

