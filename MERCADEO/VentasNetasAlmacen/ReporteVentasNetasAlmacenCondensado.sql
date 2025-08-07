-- DROP FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado(varchar, varchar, numeric);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado(p_periodo character varying,
                                                                                p_bodegas character varying,
                                                                                p_monto_minimo numeric)
    RETURNS TABLE
            (
                fecha                date,
                bodega_1             text,
                num_transacciones_1  integer,
                total_venta_1        numeric,
                bodega_2             text,
                num_transacciones_2  integer,
                total_venta_2        numeric,
                bodega_3             text,
                num_transacciones_3  integer,
                total_venta_3        numeric,
                bodega_4             text,
                num_transacciones_4  integer,
                total_venta_4        numeric,
                bodega_5             text,
                num_transacciones_5  integer,
                total_venta_5        numeric,
                bodega_6             text,
                num_transacciones_6  integer,
                total_venta_6        numeric,
                bodega_7             text,
                num_transacciones_7  integer,
                total_venta_7        numeric,
                bodega_8             text,
                num_transacciones_8  integer,
                total_venta_8        numeric,
                bodega_9             text,
                num_transacciones_9  integer,
                total_venta_9        numeric,
                bodega_10            text,
                num_transacciones_10 integer,
                total_venta_10       numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    PERFORM puntos_venta.reporte_ventas_netas_almacen_condensado_temp(
            p_periodo,
            p_bodegas,
            p_monto_minimo,
            false,
            10
            );
    RETURN QUERY
        SELECT tr.fecha,
               tr.bodega_1,
               tr.num_transacciones_1,
               tr.total_venta_1,
               tr.bodega_2,
               tr.num_transacciones_2,
               tr.total_venta_2,
               tr.bodega_3,
               tr.num_transacciones_3,
               tr.total_venta_3,
               tr.bodega_4,
               tr.num_transacciones_4,
               tr.total_venta_4,
               tr.bodega_5,
               tr.num_transacciones_5,
               tr.total_venta_5,
               tr.bodega_6,
               tr.num_transacciones_6,
               tr.total_venta_6,
               tr.bodega_7,
               tr.num_transacciones_7,
               tr.total_venta_7,
               tr.bodega_8,
               tr.num_transacciones_8,
               tr.total_venta_8,
               tr.bodega_9,
               tr.num_transacciones_9,
               tr.total_venta_9,
               tr.bodega_10,
               tr.num_transacciones_10,
               tr.total_venta_10
        FROM temp_reporte_ventas_netas tr;
END
$function$
;
