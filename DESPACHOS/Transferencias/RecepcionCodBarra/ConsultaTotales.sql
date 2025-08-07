CREATE OR REPLACE FUNCTION control_inventarios.transferencias_recepcion_calc_totales(p_transferencia varchar)
    RETURNS table
            (
                registros_totales   numeric,
                registros_recibidos numeric,
                total_enviado_un    numeric,
                total_enviado_pq    numeric,
                total_recibido_un   numeric,
                total_recibido_pq   numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_total_enviado_un    numeric;
    v_total_enviado_pq    numeric;
    v_total_recibido_un   numeric;
    v_total_recibido_pq   numeric;
    v_registros_total     numeric;
    v_registros_recibidos numeric;
BEGIN


    SELECT COUNT(t.item) total
    INTO v_registros_total
    FROM control_inventarios.transacciones t
    WHERE t.transaccion = p_transferencia
      AND t.tipo_movimiento = 'TRANSFER-'
      AND t.status IS NULL;

    SELECT COUNT(t.item) total
    INTO v_registros_recibidos
    FROM control_inventarios.transacciones t
    WHERE t.transaccion = p_transferencia
      AND t.tipo_movimiento = 'TRANSFER+'
      AND t.cantidad_recibida <> 0
      AND t.status IS NULL;

    SELECT SUM(t.cantidad) cantidad_enviado, SUM(t.cantidad_recibida) cantidad_rec
    INTO v_total_enviado_un, v_total_recibido_un
    FROM control_inventarios.transacciones t
             INNER JOIN control_inventarios.items i ON i.item = t.item
    WHERE t.transaccion = p_transferencia
      AND t.tipo_movimiento = 'TRANSFER+'
      AND i.unidad_medida = 'UN'
      AND t.status IS NULL;

    SELECT SUM(t.cantidad) cantidad_enviada, SUM(t.cantidad_recibida) cantidad_rec
    INTO v_total_enviado_pq, v_total_recibido_pq
    FROM control_inventarios.transacciones t
             INNER JOIN control_inventarios.items i ON t.item = i.item
    WHERE t.transaccion = p_transferencia
      AND t.tipo_movimiento = 'TRANSFER+'
      AND i.unidad_medida = 'PQ'
      AND t.status IS NULL;

    RETURN QUERY
        SELECT v_registros_total     AS registros_totales,
               v_registros_recibidos AS registros_recibidos,
               v_total_enviado_un    AS total_enviado_un,
               v_total_enviado_pq    AS total_enviado_pq,
               v_total_recibido_un   AS total_recibido_un,
               v_total_recibido_pq   AS total_recibido_pq;
END ;
$function$
;


SELECT registros_totales, registros_recibidos, total_enviado_un, total_enviado_pq, total_recibido_un, total_recibido_pq
-- FROM control_inventarios.transferencias_recepcion_calc_totales(' 104051076') AB;
--
-- SELECT transacciones.item,
--        items.descripcion,
--        items.unidad_medida,
--        transacciones.ubicacion,
--        SUM(transacciones.cantidad) cantidad
-- FROM control_inventarios.transacciones
--          INNER JOIN control_inventarios.items
--                     ON control_inventarios.transacciones.item = control_inventarios.items.item
-- WHERE transaccion = '" + TxtTransferencia.text + "'
--   AND tipo_movimiento = 'TRANSFER+'
--   AND status IS NULL
-- GROUP BY transacciones.item, items.descripcion, items.unidad_medida, transacciones.ubicacion
-- ORDER BY transacciones.item


