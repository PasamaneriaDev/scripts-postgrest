-- DROP FUNCTION puntos_venta.reporte_ventas_netas_almacen_mensual(varchar, varchar, numeric);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_mensual(p_periodo character varying,
                                                                             p_bodegas character varying,
                                                                             p_monto_minimo numeric,
                                                                             p_agrp_vendedor boolean)
    RETURNS TABLE
            (
                bodega            CHARACTER VARYING,
                codigo_vendedor   CHARACTER VARYING,
                nombre_vendedor   text,
                descripcion       CHARACTER VARYING,
                num_transacciones INTEGER,
                total_venta       NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT x1.bodega,
               CASE
                   WHEN p_agrp_vendedor THEN p.codigo
                   END                                AS                codigo_vendedor,
               CASE
                   WHEN p_agrp_vendedor THEN p.apellido_paterno || ' ' || p.nombre1
                   END                                AS                nombre_vendedor,
               x1.descripcion,
               COUNT(DISTINCT fd.referencia)::integer AS                num_transacciones,
               SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                         COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
        FROM puntos_venta.facturas_detalle fd
                 JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                 JOIN (SELECT DISTINCT pa.bodega, pa.bodega_primera, cc.subcentro AS descripcion
                       FROM sistema.parametros_almacenes pa
                                JOIN control_inventarios.id_bodegas ib
                                     ON pa.bodega = ib.bodega AND COALESCE(pa.bodega_primera, '') <> ib.bodega
                                LEFT JOIN activos_fijos.centros_costos cc ON cc.codigo = pa.centro_costo
                       WHERE ib.es_punto_venta
                         AND ib.fecha_fin_transacciones IS NULL) x1
                      ON x1.bodega = fd.bodega OR x1.bodega_primera = fd.bodega
                 LEFT JOIN roles.personal p ON fd.vendedor = RIGHT(p.codigo, 4) AND LEFT(p.codigo, 1) <> 'F'
        WHERE ((fc.monto_total - fc.iva) > p_monto_minimo OR p_monto_minimo = 0)
          AND fd.periodo = p_periodo
          AND (p_bodegas = '' OR x1.bodega IN (SELECT UNNEST(STRING_TO_ARRAY(p_bodegas, ','))))
        GROUP BY x1.bodega, x1.descripcion, codigo_vendedor, nombre_vendedor
        ORDER BY x1.bodega, nombre_vendedor;
END
$function$
;


