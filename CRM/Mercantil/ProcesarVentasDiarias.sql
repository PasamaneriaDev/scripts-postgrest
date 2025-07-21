-- drop function mercantil_tosi.procesar_ventas(p_usuario varchar);

CREATE OR REPLACE FUNCTION mercantil_tosi.procesar_ventas(p_usuario varchar, OUT o_numero_transaccion text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo boolean = TRUE;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Tabla Temporal
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT *
    FROM (WITH fechas_unicas AS (SELECT DISTINCT a.fecha, 'VENTA' AS tipo_operacion
                                 FROM mercantil_tosi.ventas_pasa_diario a
                                 WHERE NOT a.procesado
                                   AND a.cantidad > 0
                                 UNION
                                 SELECT DISTINCT a.fecha, 'DEVOLUCION' AS tipo_operacion
                                 FROM mercantil_tosi.ventas_pasa_diario a
                                 WHERE NOT a.procesado
                                   AND a.cantidad < 0),
               numeros_transaccion AS (SELECT fecha,
                                              tipo_operacion,
                                              sistema.transaccion_inventario_numero_obtener('001') AS numero
                                       FROM fechas_unicas)
          SELECT v.bodega
               , a.item
               , v.tipo
               , 'TRN-MER/VENTA REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
               , a.fecha
               , v.cantidad                                                 AS cantidad
               , i.costo_promedio                                           AS costo
               , '0000'                                                     AS ubicacion
               , TO_CHAR(CURRENT_DATE, 'YYYYMM')                            AS periodo
               , LPAD(nt.numero::text, 10, ' ')                             AS transaccion
               , nt.tipo_operacion
          FROM mercantil_tosi.ventas_pasa_diario a
                   CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad * -1, '040'),
                                               ('TRANSFER+', a.cantidad, 'C40')) v (tipo, cantidad, bodega)
                   JOIN control_inventarios.items i ON i.item = a.item
                   JOIN numeros_transaccion nt ON a.fecha = nt.fecha AND nt.tipo_operacion = 'VENTA'
          WHERE NOT a.procesado
            AND a.cantidad > 0
          UNION ALL
          SELECT v.bodega
               , a.item
               , v.tipo
               , 'TRN-MER/DEVOLUCION REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
               , a.fecha
               , v.cantidad                                                      AS cantidad
               , i.costo_promedio                                                AS costo
               , '0000'                                                          AS ubicacion
               , TO_CHAR(CURRENT_DATE, 'YYYYMM')                                 AS periodo
               , LPAD(nt.numero::text, 10, ' ')                                  AS transaccion
               , nt.tipo_operacion
          FROM mercantil_tosi.ventas_pasa_diario a
                   CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad, 'C40'),
                                               ('TRANSFER+', a.cantidad * -1, '040')) v (tipo, cantidad, bodega)
                   JOIN control_inventarios.items i ON i.item = a.item
                   JOIN numeros_transaccion nt ON a.fecha = nt.fecha AND nt.tipo_operacion = 'DEVOLUCION'
          WHERE NOT a.procesado
            AND a.cantidad < 0) AS rf;

    SELECT CASE
               WHEN ventas IS NOT NULL AND devoluciones IS NOT NULL THEN
                   'Venta: ' || ventas || ' - Devolucion: ' || devoluciones
               WHEN ventas IS NOT NULL THEN
                   'Venta: ' || ventas
               WHEN devoluciones IS NOT NULL THEN
                   'Devolucion: ' || devoluciones
               ELSE
                   'No hay transacciones'
               END AS resultado
    INTO o_numero_transaccion
    FROM (SELECT STRING_AGG(DISTINCT CASE WHEN tipo_operacion = 'VENTA' THEN TRIM(transaccion) END, ',') AS ventas,
                 STRING_AGG(DISTINCT CASE WHEN tipo_operacion = 'DEVOLUCION' THEN TRIM(transaccion) END,
                            ',')                                                                         AS devoluciones
          FROM ajuste_tmp) t;

    -- Inserta Transacciones de Entrega
    WITH tran
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (transaccion, bodega, item, referencia, anio_trimestre, tipo_movimiento, fecha, cantidad, costo,
                      modulo, documento, ubicacion, precio, creacion_usuario, es_psql)
                     SELECT r1.transaccion
                          , r1.bodega
                          , r1.item
                          , r1.referencia
                          , 0
                          , r1.tipo
                          , CURRENT_DATE
                          , r1.cantidad
                          , r1.costo
                          , 'IC'
                          , r1.transaccion
                          , r1.ubicacion
                          , 0
                          , p_usuario
                          , TRUE
                     FROM ajuste_tmp AS r1
                     RETURNING it.*)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'INSERT1'
         , 'ICTRAN01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ ' --, anio_trime WITH ' ||  CAST(NEW.anio_trimestre As VARCHAR) ||
         , ''
         , FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
                  '(ttranno, loctid, item, ref, anio_trime, trantyp, ' ||
                  ' tdate, sqty, tcost, applid, docno, ' ||
                  ' tstore, price, adduser, adddate, addtime, per) ' ||
                  'VALUES (' ||
                  '  [%s], [%s], [%s], [%s], ' ||
                  '  %s, [%s], {^%s}, %s, ' ||
                  '  %s, [%s], [%s], [%s], ' ||
                  '  %s, [%s], {^%s}, [%s], ' ||
                  '  [%s])',
                  s.transaccion, s.bodega, RPAD(s.item, 15, ' '), s.referencia,
                  s.anio_trimestre, lista_materiales.tipo_movimiento_spp_x_codigo(s.tipo_movimiento),
                  TO_CHAR(s.fecha, 'YYYY-MM-DD'), s.cantidad, s.costo,
                  s.modulo, s.documento, s.ubicacion,
                  s.precio, s.creacion_usuario, TO_CHAR(s.fecha, 'YYYY-MM-DD'), ('now'::text)::time(0),
                  TO_CHAR(CURRENT_DATE, 'YYYYMM')
           )
    FROM tran AS s
    WHERE _interface_activo;

    UPDATE mercantil_tosi.ventas_pasa_diario a
    SET procesado = TRUE
    WHERE NOT a.procesado;

    -- Recibir Transacciones de Devolución
    perform puntos_venta.recepcion_transferencia_excepcion(a.transaccion, a.bodega, a.item, a.cantidad, p_usuario, 0)
    FROM ajuste_tmp a
    WHERE a.tipo_operacion = 'DEVOLUCION'
      AND a.tipo = 'TRANSFER+';
END ;
$function$