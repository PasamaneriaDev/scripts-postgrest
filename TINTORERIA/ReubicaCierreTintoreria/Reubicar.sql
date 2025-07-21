-- DROP FUNCTION control_inventarios.reubicacion_orden_tintoreria(varchar, text);

CREATE OR REPLACE FUNCTION control_inventarios.reubicacion_orden_tintoreria(p_datajs character varying, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Tabla Temporal
    DROP TABLE IF EXISTS ajuste_tmp;
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT a.bodega
         , a.item
         , v.tipo
         , 'De ' || a.ubicacion_origen || ' a ' || a.ubicacion_destino AS referencia
         , v.cantidad                                                  AS cantidad
         , i.costo_promedio                                            AS costo
         , v.ubicacion
         , TO_CHAR(CURRENT_DATE, 'YYYYMM')                             AS periodo
         , LPAD(x.numero::text, 10, ' ')                               AS transaccion
    FROM JSON_TO_RECORDSET(p_datajs::json) a (item text, cantidad numeric, ubicacion_origen text,
                                              ubicacion_destino text, bodega text)
             CROSS JOIN LATERAL ( VALUES ('REUB CANT-', a.cantidad * -1, a.ubicacion_origen),
                                         ('REUB CANT+', a.cantidad,
                                          a.ubicacion_destino)) v (tipo, cantidad, ubicacion)
             JOIN control_inventarios.items i ON i.item = a.item
             CROSS JOIN LATERAL sistema.transaccion_inventario_numero_obtener(CASE
                                                                                  WHEN a.item || a.ubicacion_destino = a.item || a.ubicacion_destino
                                                                                      THEN '001' END) x;

    -- Inserta Transacciones de Entrega
    WITH tran
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (item, bodega, ubicacion, transaccion, fecha, tipo_movimiento, referencia, modulo, costo, cantidad,
                      periodo, creacion_usuario, es_psql)
                     SELECT r1.item
                          , r1.bodega
                          , r1.ubicacion
                          , r1.transaccion
                          , CURRENT_DATE
                          , r1.tipo
                          , r1.referencia
                          , 'TP'
                          , r1.costo
                          , r1.cantidad
                          , r1.periodo
                          , p_usuario
                          , TRUE
                     FROM ajuste_tmp AS r1
                     RETURNING it.item, it.bodega, it.ubicacion, it.transaccion,
                         it.fecha, it.tipo_movimiento, it.referencia, it.modulo,
                         it.costo, it.cantidad, it.periodo, it.creacion_usuario,
                         it.creacion_fecha, it.creacion_hora, it.secuencia)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'TRABAJO EN PROCESO'
         , 'INSERT1'
         , 'ICTRAN01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\'
         , ''
         , FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
                  '(item, loctid, tstore, ttranno, ' ||
                  ' tdate, trantyp, ref, applid, ' ||
                  ' tcost, sqty, per, adduser, ' ||
                  ' adddate, addtime, secu_post) ' ||
                  'VALUES ([%s], [%s], [%s], [%s], ' ||
                  '        {^%s}, [%s], [%s], [%s], ' ||
                  '        %s, %s, [%s], [%s], ' ||
                  '        {^%s}, [%s], [%s])',
                  s.item, s.bodega, s.ubicacion, s.transaccion,
                  TO_CHAR(s.fecha, 'YYYY/MM/DD'), lista_materiales.tipo_movimiento_spp_x_codigo(s.tipo_movimiento),
                  s.referencia, s.modulo,
                  s.costo::VARCHAR, s.cantidad::VARCHAR, s.periodo, s.creacion_usuario,
                  s.creacion_fecha, s.creacion_hora, s.secuencia::VARCHAR)
    FROM tran AS s
    WHERE _interface_activo;

    -- Actualiza comentario
    WITH cte AS (
        UPDATE control_inventarios.ubicaciones AS u
            SET comentario = a.comentario
            FROM JSON_TO_RECORDSET(p_datajs::json) a (item text, ubicacion_destino text, bodega text, comentario text)
            WHERE u.item = a.item
                AND u.bodega = a.bodega
                AND u.ubicacion = a.ubicacion_destino
                AND (LEFT(a.item, 1) = '7' OR LEFT(a.item, 1) = '4')
                AND COALESCE(u.comentario, '') = ''
            RETURNING u.item, u.bodega, u.ubicacion, u.comentario)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'TRABAJO EN PROCESO'
         , 'UPDATE1'
         , 'iciqty01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\'
         , ''
         , 'UPDATE V:\SBTPRO\ICDATA\iciqty01 ' ||
           'SET comentario = [' || s.comentario || '] ' ||
           'Where item = [' || RPAD(s.item, 15, ' ') || '] ' ||
           '  And loctid = [' || RPAD(s.bodega, 3, ' ') || '] ' ||
           '  And qstore = [' || RPAD(s.ubicacion, 4, ' ') || '] '
    FROM CTE AS s
    WHERE _interface_activo;

    UPDATE trabajo_proceso.tintoreria_ordenes_enviadas AS te
    SET cantidad_reubica = cantidad_reubica + a.cantidad
    FROM JSON_TO_RECORDSET(p_datajs::json) a (cantidad numeric, tintoreria_ordenes_enviadas_id integer)
    WHERE te.tintoreria_ordenes_enviadas_id = a.tintoreria_ordenes_enviadas_id;
END ;
$function$
;
