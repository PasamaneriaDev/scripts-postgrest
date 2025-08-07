-- DROP FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado_vend(varchar, varchar, numeric);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado_vend(p_periodo character varying,
                                                                                     p_bodegas character varying,
                                                                                     p_monto_minimo numeric)
    RETURNS TABLE
            (
                fecha               date,
                bodega_1            text,
                nombre_vendedor_1   text,
                num_transacciones_1 integer,
                total_venta_1       numeric,
                bodega_2            text,
                nombre_vendedor_2   text,
                num_transacciones_2 integer,
                total_venta_2       numeric,
                bodega_3            text,
                nombre_vendedor_3   text,
                num_transacciones_3 integer,
                total_venta_3       numeric,
                bodega_4            text,
                nombre_vendedor_4   text,
                num_transacciones_4 integer,
                total_venta_4       numeric,
                bodega_5            text,
                nombre_vendedor_5   text,
                num_transacciones_5 integer,
                total_venta_5       numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    perform puntos_venta.reporte_ventas_netas_almacen_condensado_temp(
            p_periodo,
            p_bodegas,
            p_monto_minimo,
            TRUE,
            5
         );

    RETURN QUERY
        SELECT tr.fecha,
               tr.bodega_1,
               tr.nombre_vendedor_1,
               tr.num_transacciones_1,
               tr.total_venta_1,
               tr.bodega_2,
               tr.nombre_vendedor_2,
               tr.num_transacciones_2,
               tr.total_venta_2,
               tr.bodega_3,
               tr.nombre_vendedor_3,
               tr.num_transacciones_3,
               tr.total_venta_3,
               tr.bodega_4,
               tr.nombre_vendedor_4,
               tr.num_transacciones_4,
               tr.total_venta_4,
               tr.bodega_5,
               tr.nombre_vendedor_5,
               tr.num_transacciones_5,
               tr.total_venta_5
        FROM temp_reporte_ventas_netas tr;
END
$function$
;
