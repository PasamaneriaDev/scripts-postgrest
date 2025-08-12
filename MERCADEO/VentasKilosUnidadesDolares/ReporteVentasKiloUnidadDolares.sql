/*
DROP FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(p_tipo_reporte varchar, p_item_inicial varchar,
                                                              p_item_final varchar, p_fecha_inicial varchar,
                                                              p_fecha_final varchar)
*/

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(p_item_inicial varchar,
                                                                           p_item_final varchar,
                                                                           p_fecha_inicial varchar,
                                                                           p_fecha_final varchar)
    RETURNS TABLE
            (
                linea               text,
                descripcion_seccion text,
                unidad_medida       varchar,
                cantidad            numeric,
                peso                numeric,
                precio              numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        WITH cte_ventas AS (SELECT df.item,
                                   r1.unidad_medida,
                                   (df.cantidad)                     cantidad,
                                   ROUND((r1.peso * df.cantidad), 3) peso,
                                   (df.total_precio)                 precio
                            FROM puntos_venta.facturas_detalle df
                                     LEFT JOIN control_inventarios.items r1 ON df.item = r1.item
                            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
                              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
                              AND (df.status IS NULL)
                              AND (r1.es_vendible = TRUE AND r1.es_fabricado = TRUE)
                              AND (LEFT(df.item, 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'Z', 'B'))
                            UNION ALL
                            SELECT df.item,
                                   r1.unidad_medida,
                                   (df.cantidad)                     cantidad,
                                   ROUND((r1.peso * df.cantidad), 3) peso,
                                   (df.total_precio)                 precio
                            FROM cuentas_cobrar.facturas_detalle df
                                     LEFT JOIN control_inventarios.items r1 ON df.item = r1.item
                            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
                              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
                              AND (df.status IS NULL)
                              AND LEFT(df.referencia, 1) NOT IN ('X', 'P')
                              AND (r1.es_vendible = TRUE AND r1.es_fabricado = TRUE)
                              AND (LEFT(df.item, 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'Z', 'B'))),
             cte_linea AS (SELECT CASE
                                      WHEN LEFT(df.item, 1) <> 'B' THEN
                                          CASE
                                              WHEN LEFT(df.item, 1) = 'D' THEN
                                                  '1'
                                              ELSE
                                                  LEFT(df.item, 1)
                                              END
                                      ELSE
                                          LEFT(df.item, 5)
                                      END AS clave,
                                  CASE
                                      WHEN LEFT(df.item, 1) <> 'B' THEN LEFT(df.item, 1)
                                      ELSE LEFT(df.item, 5)
                                      END AS linea,
                                  *
                           FROM cte_ventas df)
        SELECT cl.linea,
               isc.seccion::text      AS descripcion_seccion,
               cl.unidad_medida,
               SUM(cl.cantidad) AS cantidad,
               SUM(cl.peso)     AS peso,
               SUM(cl.precio)   AS precio
        FROM cte_linea cl
                 LEFT JOIN control_inventarios.item_seccion isc ON LEFT(cl.linea, 1) = isc.codigo
        GROUP BY cl.linea, cl.unidad_medida, isc.seccion
        ORDER BY cl.linea, cl.unidad_medida;

END
$function$
;
