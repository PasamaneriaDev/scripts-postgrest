SELECT ''::varchar                          item_inicial,
       'p_item_final'::varchar              item_final,
       'fecha_inicial'::varchar             fecha_inicial,
       'fecha_final'::varchar               fecha_final,
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
       ROUND(SUM(r1.peso * df.cantidad), 3) peso,
       SUM(df.cantidad)                     cantidad,
       SUM(df.total_precio)                 precio
FROM puntos_venta.facturas_detalle df
         LEFT JOIN(SELECT i.item          item,
                          i.unidad_medida unidad_medida,
                          i.peso          peso,
                          i.es_vendible   vendible,
                          i.es_fabricado  fabricado
                   FROM control_inventarios.items i) r1 ON df.item = r1.item
WHERE (df.item >= '0BP120000005' AND df.item <= '157500S6206421')
  AND (df.fecha BETWEEN TO_DATE('2023-11-01', 'YYYY-MM-DD') AND TO_DATE('2024-11-22', 'YYYY-MM-DD'))
  AND (df.status IS NULL)
  AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
  AND (LEFT(df.ITEM, 1) != 'Z')
GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
ORDER BY primer_digito ASC, unidad_medida ASC;



SELECT *
FROM puntos_venta.reporte_ventas_x_kilo_unidad_dolar('PUNTO VENTA',
                                                     '0BP120000005',
                                                     '157500S6206421',
                                                     '2023-11-01',
                                                     '2024-11-22')



SELECT -- p_item_inicial::varchar              item_inicial,
--        p_item_final::varchar                item_final,
--        p_fecha_inicial::varchar             fecha_inicial,
--        p_fecha_final::varchar               fecha_final,
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
WHERE (df.item >= '0BP120000005' AND df.item <= '157500S6206421')
  AND (df.fecha BETWEEN TO_DATE('2023-11-01', 'YYYY-MM-DD') AND TO_DATE('2024-11-22', 'YYYY-MM-DD'))
  AND (df.status IS NULL)
  AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
  AND (LEFT(df.ITEM, 1) != 'Z')
GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
ORDER BY primer_digito ASC, unidad_medida ASC;




select *
from control_inventarios.items
order by item



select *
from puntos_venta.reporte_ventas_x_kilo_unidad_dolar('PUNTO VENTAs',
                                                     '10422246213101',
                                                     '157500S6206421',
                                                     '2024-10-01',
                                                     '2024-10-31')








            SELECT
                   r1.unidad_medida,
                   df.cantidad, r1.peso, df.total_precio
--                    SUM(df.cantidad)                     cantidad,
--                    ROUND(SUM(r1.peso * df.cantidad), 2) peso,
--                    SUM(df.total_precio)                 precio
            FROM puntos_venta.facturas_detalle df
                     LEFT JOIN(SELECT i.item          item,
                                      i.unidad_medida unidad_medida,
                                      i.peso          peso,
                                      i.es_vendible   vendible,
                                      i.es_fabricado  fabricado
                               FROM control_inventarios.items i) r1 ON df.item = r1.item
            WHERE (df.item >= '10422246213101' AND df.item <= '10442126427101')
              AND (df.fecha BETWEEN TO_DATE('2024-10-01', 'YYYY-MM-DD') AND TO_DATE('2024-10-31', 'YYYY-MM-DD'))
              AND (df.status IS NULL)
              AND (r1.vendible = TRUE AND r1.fabricado = TRUE)
              AND (LEFT(df.ITEM, 1) != 'Z')
--             GROUP BY LEFT(df.ITEM, 1), r1.unidad_medida
--             ORDER BY primer_digito ASC, unidad_medida ASC;



  sql=" SELECT bodegas.bodega, bodegas.descripcion "
  sql=sql+" FROM control_inventarios.id_bodegas bodegas"
  sql=sql+" where es_punto_venta=true "
  sql=sql+" order by bodega asc "

SELECT bodega, descripcion
FROM control_inventarios.id_bodegas
where es_punto_venta=true
and bodega = $1


select x.fecha, pr1.periodo, pr1.monto_minimo,
       pr1.bodega || ' ' || pr1.descripcion as bodega_1, pr1.num_transacciones as num_transacciones_1, pr1.total_venta as total_venta_1,
       pr2.bodega || ' ' || pr2.descripcion as bodega_2, pr2.num_transacciones as num_transacciones_2, pr2.total_venta as total_venta_2,
       pr3.bodega || ' ' || pr3.descripcion as bodega_3, pr3.num_transacciones as num_transacciones_3, pr3.total_venta as total_venta_3

from
(SELECT GENERATE_SERIES(
                DATE_TRUNC('month', TO_DATE('202410', 'YYYYMM')),
                DATE_TRUNC('month', TO_DATE('202410', 'YYYYMM')) + INTERVAL '1 month' - INTERVAL '1 day',
                '1 day'
        )::date AS fecha) as x
LEFT join puntos_venta.reporte_ventas_netas_almacen_detallado('202410', '020', 0) AS pr1 ON pr1.fecha = x.fecha
LEFT join puntos_venta.reporte_ventas_netas_almacen_detallado('202410', '021', 0) AS pr2 ON pr2.fecha = x.fecha
LEFT join puntos_venta.reporte_ventas_netas_almacen_detallado('202410', 'x', 0) AS pr3 ON pr3.fecha = x.fecha
LEFT join puntos_venta.reporte_ventas_netas_almacen_detallado('202410', '025', 0) AS pr4 ON pr4.fecha = x.fecha;


SELECT *--string_agg(bodega, ', ') AS bodegas
FROM control_inventarios.id_bodegas
WHERE es_punto_venta and controla_toc;


select *
from puntos_venta.reporte_ventas_netas_almacen_condensado('202409', '020,025,006', 0)}}}



select bodega
from control_inventarios.id_bodegas
where bodega = '020'


select *
from puntos_venta.reporte_ventas_netas_almacen_condensado('202409', '020,025,006', 0);


WITH bodega_list AS (SELECT bodega
                     FROM control_inventarios.id_bodegas
                     WHERE es_punto_venta
                     ORDER BY bodega
                     LIMIT 10 OFFSET (1 * 10))
SELECT STRING_AGG(bodega, ', ') AS bodegas
FROM bodega_list;


WITH bodega_list AS (SELECT bodega,
                            CEIL(ROW_NUMBER() OVER (ORDER BY bodega) / 10.0) AS grp
                     FROM control_inventarios.id_bodegas
                     WHERE es_punto_venta
                       AND controla_toc)
SELECT STRING_AGG(bodega, ',') AS bodegas
FROM bodega_list
GROUP BY grp
ORDER BY grp


"WITH bodega_list AS (SELECT UNNEST(STRING_TO_ARRAY('006,020,021,022,024,025,026,027,028,120,121,122,123,124,125,126,127,128,129,130', ',')) AS bodega, " + _
"                            CEIL(ROW_NUMBER() OVER (ORDER BY UNNEST(STRING_TO_ARRAY( " + _
"                                    '006,020,021,022,024,025,026,027,028,120,121,122,123,124,125,126,127,128,129,130', " + _
"                                    ','))) / 10.0)                                               AS grp) " + _
"SELECT STRING_AGG(bodega, ',') AS bodegas " + _
"FROM bodega_list " + _
"GROUP BY grp " + _



CREATE INDEX idx_facturas_detalle_periodo ON puntos_venta.facturas_detalle(periodo);



select *
from puntos_venta.facturas_detalle








SELECT *
FROM puntos_venta.reporte_ventas_netas_almacen_mensual('202409', '', 0)





