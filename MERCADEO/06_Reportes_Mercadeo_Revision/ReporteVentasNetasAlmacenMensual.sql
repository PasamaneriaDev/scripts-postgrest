-- drop function puntos_venta.reporte_ventas_netas_almacen_detallado(p_periodo varchar, p_bodegas varchar, p_monto_minimo numeric)

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_mensual(p_periodo varchar, p_bodegas varchar, p_monto_minimo numeric)
    RETURNS TABLE
            (
                periodo           varchar,
                monto_minimo      numeric,
                bodega            varchar,
                descripcion       varchar,
                num_transacciones integer,
                total_venta       numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT p_periodo                              AS                periodo,
               p_monto_minimo                         AS                monto_minimo,
               x1.bodega,
               x1.descripcion,
               COUNT(DISTINCT fd.referencia)::integer AS                num_transacciones,
               SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                         COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
        FROM puntos_venta.facturas_detalle fd
                 JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                 JOIN
             (SELECT DISTINCT pa.bodega, pa.bodega_primera, cc.subcentro as descripcion
              FROM sistema.parametros_almacenes pa
                       JOIN control_inventarios.id_bodegas ib
                            ON pa.bodega = ib.bodega AND COALESCE(pa.bodega_primera, '') <> ib.bodega
              LEFT JOIN activos_fijos.centros_costos cc on cc.codigo = pa.centro_costo
              WHERE ib.es_punto_venta
                AND ib.fecha_fin_transacciones IS NULL) x1
             ON x1.bodega = fd.bodega OR x1.bodega_primera = fd.bodega
        WHERE ((fc.monto_total - fc.iva) > p_monto_minimo OR p_monto_minimo = 0)
          AND fd.periodo = p_periodo
          AND (p_bodegas = '' OR x1.bodega IN (SELECT UNNEST(STRING_TO_ARRAY(p_bodegas, ','))))
        GROUP BY x1.bodega, x1.descripcion
        -- HAVING SUM(fd.total_precio) > p_monto_minimo
        ORDER BY x1.bodega;
END
$function$
;
