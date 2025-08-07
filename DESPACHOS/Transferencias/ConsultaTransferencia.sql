-- drop function control_inventarios.transferencias_consulta_plus_minus(p_transferencia varchar);

CREATE OR REPLACE FUNCTION control_inventarios.transferencias_consulta_plus_minus(p_transferencia varchar)
    RETURNS table
            (
                transaccion         varchar,
                bodega_desde        text,
                bodega_hasta        text,
                has_transfer_plus   boolean,
                has_transfer_minus  boolean,
                recepcion_completa  integer,
                cantidad_recepcion  numeric,
                recepcion_pendiente integer
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT t.transaccion,
               MAX(CASE WHEN t.tipo_movimiento = 'TRANSFER-' THEN t.bodega END)                   AS bodega_desde,
               MAX(CASE WHEN t.tipo_movimiento = 'TRANSFER+' THEN t.bodega END)                   AS bodega_hasta,
               COUNT(DISTINCT CASE WHEN t.tipo_movimiento = 'TRANSFER+' THEN 1 END) > 0           AS has_transfer_plus,
               COUNT(DISTINCT CASE WHEN t.tipo_movimiento = 'TRANSFER-' THEN 1 END) > 0           AS has_transfer_minus,
               SUM(CASE
                       WHEN t.tipo_movimiento = 'TRANSFER+' AND COALESCE(t.recepcion_completa, FALSE) THEN 1
                       ELSE 0 END)::integer                                                       AS recepcion_completa,
               SUM(CASE WHEN t.tipo_movimiento = 'TRANSFER+' THEN t.cantidad_recibida ELSE 0 END) AS cantidad_recepcion,
               SUM(CASE
                       WHEN t.tipo_movimiento = 'TRANSFER+' AND NOT COALESCE(t.recepcion_completa, FALSE) THEN 1
                       ELSE 0 END)::integer                                                       AS recepcion_pendiente
        FROM control_inventarios.transacciones t
        WHERE t.transaccion = p_transferencia
        GROUP BY t.transaccion;
END ;
$function$
;



SELECT ab.transaccion,
       bodega_desde,
       bodega_hasta,
       has_transfer_plus,
       has_transfer_minus,
       recepcion_completa,
       cantidad_recepcion,
       recepcion_pendiente
FROM control_inventarios.transferencias_consulta_plus_minus('  51698734') AS ab;

SELECT *
FROM control_inventarios.transacciones
WHERE transaccion = '  51698734';


