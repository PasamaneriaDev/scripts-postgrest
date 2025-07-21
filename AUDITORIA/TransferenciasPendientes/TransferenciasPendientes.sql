CREATE OR REPLACE FUNCTION control_inventarios.transferencias_pendientes(p_transaccion varchar, p_solo_diferencias boolean)
    RETURNS TABLE
            (
                fecha             date,
                item              varchar,
                descripcion       varchar,
                cantidad          numeric,
                costo             numeric,
                bodega_origen     varchar,
                ubicacion_origen  varchar,
                bodega_destino    varchar,
                ubicacion_destino varchar,
                cantidad_recibida numeric,
                fecha_recepcion   date,
                referencia        varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        WITH t1 AS (SELECT r1.transaccion,
                           r1.bodega,
                           r1.item,
                           r1.fecha,
                           r1.referencia,
                           r1.ubicacion,
                           ABS(r1.cantidad)                                                               AS cantidad,
                           r1.costo,
                           ROW_NUMBER() OVER (PARTITION BY r1.item, r1.transaccion ORDER BY r1.secuencia) AS orden
                    FROM control_inventarios.transacciones r1
                    WHERE r1.transaccion = p_transaccion
                      AND r1.tipo_movimiento = 'TRANSFER-'),
             t2 AS (SELECT r1.transaccion,
                           r1.bodega,
                           r1.item,
                           r1.ubicacion,
                           r1.cantidad_recibida                                                           AS cantidad_recibida,
                           r1.fecha                                                                       AS fecha_recepcion,
                           ROW_NUMBER() OVER (PARTITION BY r1.item, r1.transaccion ORDER BY r1.secuencia) AS orden
                    FROM control_inventarios.transacciones r1
                    WHERE r1.transaccion = p_transaccion
                      AND r1.tipo_movimiento = 'TRANSFER+')
        SELECT t1.fecha,
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
        FROM t1
                 LEFT JOIN
             t2
             ON t1.transaccion = t2.transaccion
                 AND t1.item = t2.item
                 AND t1.orden = t2.orden
                 LEFT JOIN
             control_inventarios.items i
             ON i.item = t1.item
        WHERE (p_solo_diferencias IS FALSE OR t1.cantidad <> t2.cantidad_recibida);
END;
$function$
;