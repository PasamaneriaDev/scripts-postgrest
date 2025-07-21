-- drop function puntos_venta.reporte_ventas_x_kilo_unidad_dolar(p_tipo_reporte varchar,p_item_inicial varchar,p_item_final varchar,p_fecha_inicial varchar,p_fecha_final varchar)

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(p_tipo_reporte varchar,
                                                                           p_item_inicial varchar,
                                                                           p_item_final varchar,
                                                                           p_fecha_inicial varchar,
                                                                           p_fecha_final varchar)
    RETURNS TABLE
            (
                titulo_reporte      text,
                item_inicial        varchar,
                item_final          varchar,
                fecha_inicial       varchar,
                fecha_final         varchar,
                primer_digito       text,
                descripcion_seccion text,
                tipo_venta          varchar,
                unidad_medida       varchar,
                cantidad            numeric,
                peso                numeric,
                precio              numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    IF p_tipo_reporte = 'PUNTO VENTA' THEN
        RETURN QUERY
            SELECT 'Puntos de Venta'::text AS                 titulo_reporte,
                   p_item_inicial::varchar              item_inicial,
                   p_item_final::varchar                item_final,
                   p_fecha_inicial::varchar             fecha_inicial,
                   p_fecha_final::varchar               fecha_final,
                   LEFT(df.ITEM, 1)                     primer_digito,
                   CASE
                       WHEN LEFT(df.ITEM, 1) = '1' THEN 'Confecciones'
                       WHEN LEFT(df.ITEM, 1) = '2' THEN 'Telares'
                       WHEN LEFT(df.ITEM, 1) = '3' THEN 'Trenzadoras'
                       WHEN LEFT(df.ITEM, 1) = '4' THEN 'Tintoreria'
                       WHEN LEFT(df.ITEM, 1) = '5' THEN 'Calcetines'
                       WHEN LEFT(df.ITEM, 1) = '6' THEN 'Encajes'
                       WHEN LEFT(df.ITEM, 1) = '7' THEN 'Mallas'
                       WHEN LEFT(df.ITEM, 1) = '9' THEN 'Seda'
                       WHEN LEFT(df.ITEM, 1) = 'B' THEN 'Hilos B'
                       WHEN LEFT(df.ITEM, 1) = 'M' THEN 'Fundas Almacenes'
                       WHEN LEFT(df.ITEM, 1) = 'W' THEN 'Articulos Promocionales'
                       WHEN LEFT(df.ITEM, 1) = 'Z' THEN 'Desperdicio'
                       END                              descripcion_seccion,
                   'Punto de Venta'::varchar            tipo_venta,
                   r1.unidad_medida,
                   SUM(df.cantidad)                     cantidad,
                   ROUND(SUM(r1.peso * df.cantidad), 3) peso,
                   SUM(df.total_precio)                 precio
            FROM puntos_venta.facturas_detalle df
                     LEFT JOIN(SELECT i.item          item,
                                      i.unidad_medida unidad_medida,
                                      i.peso          peso,
                                      i.es_vendible   vendible,
                                      i.es_fabricado  fabricado
                               FROM control_inventarios.items i) r1 ON df.item = r1.item
            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
              AND (df.status IS NULL)
              AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
              AND (LEFT(df.ITEM, 1) != 'Z')
            GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
            ORDER BY primer_digito ASC, unidad_medida ASC;

    ELSEIF p_tipo_reporte = 'MAYORISTA' THEN

        RETURN QUERY
            SELECT 'Mayorista'::text AS                       titulo_reporte,
                   p_item_inicial::varchar              item_inicial,
                   p_item_final::varchar                item_final,
                   p_fecha_inicial::varchar             fecha_inicial,
                   p_fecha_final::varchar               fecha_final,
                   LEFT(df.ITEM, 1)                     primer_digito,
                   CASE
                       WHEN LEFT(df.ITEM, 1) = '1' THEN 'Confecciones'
                       WHEN LEFT(df.ITEM, 1) = '2' THEN 'Telares'
                       WHEN LEFT(df.ITEM, 1) = '3' THEN 'Trenzadoras'
                       WHEN LEFT(df.ITEM, 1) = '4' THEN 'Tintoreria'
                       WHEN LEFT(df.ITEM, 1) = '5' THEN 'Calcetines'
                       WHEN LEFT(df.ITEM, 1) = '6' THEN 'Encajes'
                       WHEN LEFT(df.ITEM, 1) = '7' THEN 'Mallas'
                       WHEN LEFT(df.ITEM, 1) = '9' THEN 'Seda'
                       WHEN LEFT(df.ITEM, 1) = 'B' THEN 'Hilos B'
                       WHEN LEFT(df.ITEM, 1) = 'M' THEN 'Fundas Almacenes'
                       WHEN LEFT(df.ITEM, 1) = 'W' THEN 'Articulos Promocionales'
                       WHEN LEFT(df.ITEM, 1) = 'Z' THEN 'Desperdicio'
                       END                              descripcion_seccion,
                   'Mayoristas'::varchar                tipo_venta,
                   r1.unidad_medida,
                   SUM(df.cantidad)                     cantidad,
                   ROUND(SUM(r1.peso * df.cantidad), 3) peso,
                   SUM(df.total_precio)                 precio
            FROM cuentas_cobrar.facturas_detalle df
                     LEFT JOIN(SELECT i.item          item,
                                      i.unidad_medida unidad_medida,
                                      i.peso          peso,
                                      i.es_vendible   vendible,
                                      i.es_fabricado  fabricado
                               FROM control_inventarios.items i) r1 ON df.item = r1.item
            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
              AND (df.status IS NULL)
              AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
              AND (LEFT(df.ITEM, 1) != 'Z')
            GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
            ORDER BY primer_digito ASC, unidad_medida ASC;

    ELSE -- TODO

        RETURN QUERY
            SELECT 'Puntos de Venta + Mayorista' AS     titulo_reporte,
                   p_item_inicial::varchar              item_inicial,
                   p_item_final::varchar                item_final,
                   p_fecha_inicial::varchar             fecha_inicial,
                   p_fecha_final::varchar               fecha_final,
                   LEFT(df.ITEM, 1)                     primer_digito,
                   CASE
                       WHEN LEFT(df.ITEM, 1) = '1' THEN 'Confecciones'
                       WHEN LEFT(df.ITEM, 1) = '2' THEN 'Telares'
                       WHEN LEFT(df.ITEM, 1) = '3' THEN 'Trenzadoras'
                       WHEN LEFT(df.ITEM, 1) = '4' THEN 'Tintoreria'
                       WHEN LEFT(df.ITEM, 1) = '5' THEN 'Calcetines'
                       WHEN LEFT(df.ITEM, 1) = '6' THEN 'Encajes'
                       WHEN LEFT(df.ITEM, 1) = '7' THEN 'Mallas'
                       WHEN LEFT(df.ITEM, 1) = '9' THEN 'Seda'
                       WHEN LEFT(df.ITEM, 1) = 'B' THEN 'Hilos B'
                       WHEN LEFT(df.ITEM, 1) = 'M' THEN 'Fundas Almacenes'
                       WHEN LEFT(df.ITEM, 1) = 'W' THEN 'Articulos Promocionales'
                       WHEN LEFT(df.ITEM, 1) = 'Z' THEN 'Desperdicio'
                       END                              descripcion_seccion,
                   'Puntos de Venta'::varchar           tipo_venta,
                   r1.unidad_medida,
                   SUM(df.cantidad)                     cantidad,
                   ROUND(SUM(r1.peso * df.cantidad), 3) peso,
                   SUM(df.total_precio)                 precio
            FROM puntos_venta.facturas_detalle df
                     LEFT JOIN(SELECT i.item          item,
                                      i.unidad_medida unidad_medida,
                                      i.peso          peso,
                                      i.es_vendible   vendible,
                                      i.es_fabricado  fabricado
                               FROM control_inventarios.items i) r1 ON df.item = r1.item
            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
              AND (df.status IS NULL)
              AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
              AND (LEFT(df.ITEM, 1) != 'Z')
            GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
            UNION
            SELECT 'Puntos de Venta + Mayorista' AS     titulo_reporte,
                   p_item_inicial::varchar              item_inicial,
                   p_item_final::varchar                item_final,
                   p_fecha_inicial::varchar             fecha_inicial,
                   p_fecha_final::varchar               fecha_final,
                   LEFT(df.ITEM, 1)                     primer_digito,
                   CASE
                       WHEN LEFT(df.ITEM, 1) = '1' THEN 'Confecciones'
                       WHEN LEFT(df.ITEM, 1) = '2' THEN 'Telares'
                       WHEN LEFT(df.ITEM, 1) = '3' THEN 'Trenzadoras'
                       WHEN LEFT(df.ITEM, 1) = '4' THEN 'Tintoreria'
                       WHEN LEFT(df.ITEM, 1) = '5' THEN 'Calcetines'
                       WHEN LEFT(df.ITEM, 1) = '6' THEN 'Encajes'
                       WHEN LEFT(df.ITEM, 1) = '7' THEN 'Mallas'
                       WHEN LEFT(df.ITEM, 1) = '9' THEN 'Seda'
                       WHEN LEFT(df.ITEM, 1) = 'B' THEN 'Hilos B'
                       WHEN LEFT(df.ITEM, 1) = 'M' THEN 'Fundas Almacenes'
                       WHEN LEFT(df.ITEM, 1) = 'W' THEN 'Articulos Promocionales'
                       WHEN LEFT(df.ITEM, 1) = 'Z' THEN 'Desperdicio'
                       END                              descripcion_seccion,
                   'Mayoristas'::varchar                tipo_venta,
                   r1.unidad_medida,
                   SUM(df.cantidad)                     cantidad,
                   ROUND(SUM(r1.peso * df.cantidad), 3) peso,
                   SUM(df.total_precio)                 precio
            FROM cuentas_cobrar.facturas_detalle df
                     LEFT JOIN(SELECT i.item          item,
                                      i.unidad_medida unidad_medida,
                                      i.peso          peso,
                                      i.es_vendible   vendible,
                                      i.es_fabricado  fabricado
                               FROM control_inventarios.items i) r1 ON df.item = r1.item
            WHERE (df.item >= p_item_inicial AND df.item <= p_item_final)
              AND (df.fecha BETWEEN TO_DATE(p_fecha_inicial, 'YYYY-MM-DD') AND TO_DATE(p_fecha_final, 'YYYY-MM-DD'))
              AND (df.status IS NULL)
              AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
              AND (LEFT(df.ITEM, 1) != 'Z')
            GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
            ORDER BY primer_digito ASC, tipo_venta ASC, unidad_medida ASC;
    END IF;
END

$function$
;

