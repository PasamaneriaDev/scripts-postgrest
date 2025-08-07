-- DROP FUNCTION puntos_venta.reporte_ventas_netas_almacen_detallado(varchar, varchar, numeric);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_detallado(p_periodo character varying,
                                                                               p_bodegas character varying,
                                                                               p_monto_minimo numeric,
                                                                               p_agrp_vendedor boolean)
    RETURNS TABLE
            (
                bodega            character varying,
                descripcion       character varying,
                codigo_vendedor   CHARACTER VARYING,
                nombre_vendedor   text,
                num_transacciones integer,
                fecha             date,
                total_venta       numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT ib.bodega,
               ib.descripcion,
               CASE
                   WHEN p_agrp_vendedor THEN p.codigo
                   END                                AS                codigo_vendedor,
               CASE
                   WHEN p_agrp_vendedor THEN p.apellido_paterno || ' ' || p.nombre1
                   END                                AS                nombre_vendedor,
               COUNT(DISTINCT fd.referencia)::integer AS                num_transacciones,
               fd.fecha,
               SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                         COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
        FROM puntos_venta.facturas_detalle fd
                 JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                 JOIN control_inventarios.id_bodegas ib ON ib.bodega = fd.bodega
                 LEFT JOIN roles.personal p ON fd.vendedor = RIGHT(p.codigo, 4) AND LEFT(p.codigo, 1) <> 'F'
        WHERE ((fc.monto_total - fc.iva) > p_monto_minimo OR p_monto_minimo = 0)
          AND fd.periodo = p_periodo
          AND (p_bodegas = '' OR ib.bodega IN (SELECT UNNEST(STRING_TO_ARRAY(p_bodegas, ','))))
          AND ib.es_punto_venta
          AND ib.fecha_fin_transacciones IS NULL
        GROUP BY ib.bodega, ib.descripcion, fd.fecha, codigo_vendedor, nombre_vendedor
        ORDER BY ib.bodega, fd.fecha, nombre_vendedor;

END
$function$
;
