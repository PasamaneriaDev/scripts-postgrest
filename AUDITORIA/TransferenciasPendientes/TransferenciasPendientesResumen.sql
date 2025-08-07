-- DROP FUNCTION control_inventarios.transferencias_pendientes_resumen(varchar, varchar);

CREATE OR REPLACE FUNCTION control_inventarios.transferencias_pendientes_resumen(p_bodega character varying, p_ubicacion character varying)
    RETURNS TABLE
            (
                transaccion    character varying,
                fecha          date,
                bodega_origen  character varying,
                bodega_destino character varying
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_fecha_inicio date;
BEGIN
    SET WORK_MEM = '100MB';
    v_fecha_inicio = sistema.get_first_day_last_year();

    RETURN QUERY
        WITH transacciones_filtradas AS (SELECT DISTINCT r1.transaccion, r1.bodega, r1.fecha
                                         FROM control_inventarios.transacciones r1
                                                  INNER JOIN control_inventarios.id_bodegas ib
                                                             ON r1.bodega = ib.bodega AND ib.tiene_transito = TRUE
                                         WHERE r1.tipo_movimiento = 'TRANSFER+'
                                           AND r1.recepcion_completa IS DISTINCT FROM TRUE
                                           AND r1.fecha >= v_fecha_inicio
                                           AND (p_bodega = '' OR r1.bodega = p_bodega)
                                           AND (p_ubicacion = '' OR r1.ubicacion = p_ubicacion)),
             transacciones_transfer AS (SELECT DISTINCT r1.transaccion, r1.bodega
                                        FROM control_inventarios.transacciones r1
                                        WHERE r1.tipo_movimiento = 'TRANSFER-'
                                          AND EXISTS (SELECT 1
                                                      FROM transacciones_filtradas tf
                                                      WHERE tf.transaccion = r1.transaccion))
        SELECT t1.transaccion,
               t2.fecha,
               t1.bodega AS bodega_origen,
               t2.bodega AS bodega_destino
        FROM transacciones_filtradas t2
                 INNER JOIN transacciones_transfer t1 ON t1.transaccion = t2.transaccion
        ORDER BY t2.fecha;
    RESET WORK_MEM;
END;
$function$
;
