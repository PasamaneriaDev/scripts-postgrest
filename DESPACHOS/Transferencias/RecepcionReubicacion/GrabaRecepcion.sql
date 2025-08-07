-- drop function control_inventarios.recepcion_transferencia_reubicacion(p_transferencia varchar, p_datajs text, p_usuario text);

CREATE OR REPLACE FUNCTION control_inventarios.recepcion_transferencia_reubicacion(p_transferencia varchar,
                                                                                   p_es_parcial boolean,
                                                                                   p_datajs text,
                                                                                   p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo   BOOLEAN = TRUE;
    v_transferencia_rec record;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    SELECT transaccion,
           bodega_desde,
           bodega_hasta,
           has_transfer_plus,
           has_transfer_minus,
           recepcion_completa,
           cantidad_recepcion
    INTO v_transferencia_rec
    FROM control_inventarios.transferencias_consulta_plus_minus(p_transferencia);

    IF NOT found THEN
        RAISE EXCEPTION 'Transferencia % no encontrada', p_transferencia;
    END IF;

    -- RECEPCION
    PERFORM puntos_venta.recepcion_transferencia(p_transferencia, v_transferencia_rec.bodega_hasta, a.item,
                                                 a.cantidad_recibida, p_usuario)
    FROM JSON_TO_RECORDSET(p_datajs::json) AS a(item text, cantidad_recibida numeric, item_nuevo boolean)
    WHERE NOT COALESCE(a.item_nuevo, FALSE)
      AND COALESCE(a.cantidad_recibida, 0) > 0;

    -- Si envia con cantidad 0
    UPDATE control_inventarios.transacciones AS t
    SET fecha_recepcion = CURRENT_DATE,
        es_psql= TRUE
    FROM JSON_TO_RECORDSET(p_datajs::json) AS a(item text, cantidad_recibida numeric, item_nuevo boolean)
    WHERE t.item = a.item
      AND t.transaccion = p_transferencia
      AND t.tipo_movimiento = 'TRANSFER+'
      AND t.status <> 'V'
      AND NOT COALESCE(a.item_nuevo, FALSE)
      AND COALESCE(a.cantidad_recibida, 0) = 0;

    -- ITEMS NUEVOS
    WITH t AS (
        INSERT INTO control_inventarios.transferencia_errores
            (transaccion, bodega, item,
             cantidad_recibida, fecha_recepcion)
            SELECT p_transferencia                        AS transaccion,
                   v_transferencia_rec.bodega_hasta       AS bodega,
                   item,
                   (cantidad_recibida - cantidad_enviada) AS cantidad_recibida,
                   CURRENT_DATE                           AS fecha_recepcion
            FROM JSON_TO_RECORDSET(p_datajs::json) AS a(item text,
                                                        cantidad_enviada numeric,
                                                        cantidad_recibida numeric,
                                                        item_nuevo boolean)
            WHERE (COALESCE(a.item_nuevo, TRUE) AND cantidad_recibida > 0)
            RETURNING transferencia_errores.*)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'INSERT1',
           'ICERRO01',
           p_usuario,
           'V:\SBTPRO\ICDATA\ ',
           '',
           FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICERRO01 (ttranno, loctid, item, reccanti, recfecha) ' ||
                  'VALUES([%s], [%s], [%s], %s, {^%s})',
                  t.transaccion, t.bodega, t.item, t.cantidad_recibida, TO_CHAR(t.fecha_recepcion, 'YYYY-MM-DD'))
    FROM t
    WHERE _interface_activo;

    -- REUBICACION
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT r1.*, LPAD(x.numero::text, 10, ' ') AS transaccion
    FROM (SELECT v_transferencia_rec.bodega_hasta   AS bodega
               , a.item
               , v.tipo
               , ROUND((CASE
                            WHEN a.cantidad_recibida > a.cantidad_enviada
                                THEN a.cantidad_enviada
                            ELSE a.cantidad_recibida END) * v.operador,
                       i.numero_decimales::integer) AS cantidad
               , i.costo_promedio                   AS costo
               , v.ubicacion
          FROM JSON_TO_RECORDSET(p_datajs::json) a (item text, cantidad_enviada numeric, cantidad_recibida numeric,
                                                    item_nuevo boolean, ubicacion_ini text, ubicacion_fin text)
                   JOIN control_inventarios.items i ON i.item = a.item
                   CROSS JOIN LATERAL ( VALUES ('REUB CANT-', -1, a.ubicacion_ini),
                                               ('REUB CANT+', 1, a.ubicacion_fin)) v (tipo, operador, ubicacion)
          WHERE a.cantidad_recibida > 0
            AND a.ubicacion_fin <> '') r1
             INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener('001') x
                        ON TRUE;

    WITH tran
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (transaccion, bodega, item, tipo_movimiento, fecha,
                      cantidad, costo, modulo, documento, ubicacion,
                      creacion_usuario, referencia, es_psql,
                      periodo)
                     SELECT r1.transaccion
                          , r1.bodega
                          , r1.item
                          , r1.tipo
                          , CURRENT_DATE
                          , r1.cantidad
                          , r1.costo
                          , 'SO'
                          , r1.transaccion
                          , r1.ubicacion
                          , p_usuario
                          , 'REU-EXI / REUBICACION ' || p_transferencia
                          , TRUE
                          , TO_CHAR(CURRENT_DATE, 'YYYYMM')
                     FROM ajuste_tmp AS r1
                     RETURNING it.transaccion, it.bodega, it.item, it.tipo_movimiento,
                         it.fecha, it.cantidad, it.costo, it.modulo, it.documento,
                         it.ubicacion, it.creacion_usuario, it.creacion_fecha,
                         it.creacion_hora, it.referencia, it.periodo, it.secuencia)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS'
         , 'INSERT1'
         , 'ICTRAN01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
                  '(ttranno, loctid, item, trantyp, ' ||
                  ' tdate, sqty, tcost, applid, ref, ' ||
                  ' tstore, adduser, adddate, per, ' ||
                  ' secu_post, docno, addtime) ' ||
                  'VALUES ([%s], [%s], [%s], [%s], ' ||
                  '        {^%s}, %s, %s, [%s], [%s], ' ||
                  '        [%s], [%s], {^%s}, [%s],' ||
                  '        [%s], [%s], [%s])',
                  s.transaccion, s.bodega, s.item, lista_materiales.tipo_movimiento_spp_x_codigo(s.tipo_movimiento),
                  TO_CHAR(s.fecha, 'YYYY-MM-DD'), s.cantidad::VARCHAR, s.costo::VARCHAR, s.modulo, s.referencia,
                  s.ubicacion, s.creacion_usuario, TO_CHAR(s.fecha, 'YYYY-MM-DD'), s.periodo, s.secuencia, s.documento,
                  s.creacion_hora)
    FROM tran AS s
    WHERE _interface_activo;

    -- Cierra automáticamente la recepción
    IF NOT p_es_parcial THEN
        UPDATE control_inventarios.transacciones
        SET recepcion_completa = TRUE,
            es_psql= TRUE
        WHERE transaccion = p_transferencia
          AND tipo_movimiento = 'TRANSFER+'
          AND COALESCE(recepcion_completa, FALSE) = FALSE;

        INSERT
        INTO sistema.interface
            (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
        SELECT p_usuario
             , 'DESPACHOS'
             , 'UPDATE1'
             , 'V:\sbtpro\icdata\ '
             , 'ictran01'
             , ''
             , FORMAT(
                'UPDATE V:\sbtpro\icdata\ictran01 ' ||
                'SET rectrnffin = .t. ' ||
                'WHERE ttranno = [%s] ' ||
                '  AND  trantyp = [TR]', p_transferencia)
        WHERE _interface_activo;
    ELSE
        -- Cierra los que están completos
        UPDATE control_inventarios.transacciones
        SET es_psql= TRUE,
            recepcion_completa = TRUE
        WHERE transaccion = p_transferencia
          AND tipo_movimiento = 'TRANSFER+'
          AND cantidad_recibida = cantidad
          AND COALESCE(recepcion_completa, FALSE) = FALSE;

        INSERT
        INTO sistema.interface
            (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
        SELECT p_usuario
             , 'DESPACHOS'
             , 'UPDATE1'
             , 'V:\sbtpro\icdata\ '
             , 'ictran01'
             , ''
             , FORMAT(
                'UPDATE V:\sbtpro\icdata\ictran01 ' ||
                'SET rectrnffin = .t. ' ||
                'WHERE ttranno = [%s] ' ||
                '  AND trantyp = [TR] ' ||
                '  AND reccanti = sqty ', p_transferencia)
        WHERE _interface_activo;
    END IF;
END;
$function$
;
