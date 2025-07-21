-- DROP FUNCTION control_inventarios.transferencias_pendientes_todas();

CREATE OR REPLACE FUNCTION control_inventarios.transferencias_pendientes_todas()
    RETURNS TABLE
            (
                transaccion       character varying,
                fecha             date,
                item              character varying,
                descripcion       character varying,
                cantidad          numeric,
                costo             numeric,
                bodega_origen     character varying,
                ubicacion_origen  character varying,
                bodega_destino    character varying,
                ubicacion_destino character varying,
                cantidad_recibida numeric,
                fecha_recepcion   date,
                referencia        character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        WITH transacciones_analisis AS (SELECT t.transaccion
                                        FROM control_inventarios.transferencias_pendientes_resumen('', '') AS t),
             transacciones_filtradas AS (SELECT r1.transaccion,
                                                r1.bodega,
                                                r1.item,
                                                r1.ubicacion,
                                                r1.cantidad_recibida                                              AS cantidad_recibida,
                                                r1.fecha                                                          AS fecha_recepcion,
                                                r1.cantidad,
                                                ROW_NUMBER()
                                                OVER (PARTITION BY r1.item, r1.transaccion ORDER BY r1.secuencia) AS orden,
                                                r1.secuencia
                                         FROM control_inventarios.transacciones r1
                                         WHERE r1.tipo_movimiento = 'TRANSFER+'
                                           AND r1.transaccion = ANY (SELECT ta.transaccion
                                                                     FROM transacciones_analisis ta))
                ,
             transacciones_transfer AS (SELECT r1.transaccion,
                                               r1.bodega,
                                               r1.item,
                                               r1.fecha,
                                               r1.referencia,
                                               r1.ubicacion,
                                               ABS(r1.cantidad)                                                  AS cantidad,
                                               r1.costo,
                                               ROW_NUMBER()
                                               OVER (PARTITION BY r1.item, r1.transaccion ORDER BY r1.secuencia) AS orden
                                        FROM control_inventarios.transacciones r1
                                        WHERE r1.tipo_movimiento = 'TRANSFER-'
                                          AND r1.transaccion = ANY (SELECT ta.transaccion
                                                                    FROM transacciones_analisis ta))
        SELECT t1.transaccion,
               t1.fecha,
               t1.item,
               i.descripcion AS descripcion,
               t1.cantidad,
               t1.costo,
               t1.bodega     AS bodega_origen,
               t1.ubicacion  AS ubicacion_origen,
               t2.bodega     AS bodega_destino,
               t2.ubicacion  AS ubicacion_destino,
               t2.cantidad_recibida,
               t2.fecha_recepcion,
               t1.referencia
        FROM transacciones_transfer t1
                 JOIN transacciones_filtradas t2
                      ON t1.transaccion = t2.transaccion
                          AND t1.item = t2.item
                          AND t1.orden = t2.orden
                 LEFT JOIN control_inventarios.items i
                           ON i.item = t1.item
        ORDER BY t1.transaccion, t1.item;
END;
$function$
;
