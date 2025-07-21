
SELECT cuentas_cobrar.reporte_general_ventas('{
  "fecha_inicial": "2025-06-01",
  "fecha_final": "2025-06-30",
  "item_inicial": "",
  "item_final": "",
  "cliente_inicial": "",
  "cliente_final": "",
  "linea": "",
  "familia": "",
  "p_agent_bods": "{}",
  "tipo_ventas": "T",
  "tipo_reporte": "D",
  "es_tot_cliente": true,
  "es_tot_agente": false,
  "con_pedidos": false,
  "con_bodegas": true,
  "con_precios": false,
  "con_componentes": true
}');

SELECT t.*
FROM reporte_general_ventas_temp t;



SELECT item,
       MAX(CASE WHEN tipo = 'DIS' THEN precio END) AS dis_precio,
       MAX(CASE WHEN tipo = 'MAY' THEN precio END) AS may_precio,
       MAX(CASE WHEN tipo = 'PVP' THEN precio END) AS pvp_precio
FROM control_inventarios.precios
WHERE tipo IN ('DIS', 'MAY', 'PVP')
GROUP BY item

SELECT *
FROM control_inventarios.items
WHERE LEFT(item, 1) = 'B'


SELECT *
FROM lista_materiales.estructuras e
         JOIN control_inventarios.items i ON e.item = i.item
    AND e.componente LIKE '4%'
         JOIN control_inventarios.bodegas b ON e.componente = b.item AND b.bodega = 'MTB'
WHERE LEFT(i.item, 1) = 'B'
  AND b.existencia <> 0
--AND (e.item, e.componente) = ('BP12090203T', '4')


SELECT e.componente, b.existencia, b.buffer
FROM lista_materiales.estructuras e
         LEFT JOIN control_inventarios.bodegas b ON e.componente = b.item AND b.bodega = 'MTB'
WHERE e.item = 'BM12030859H'
  AND e.componente LIKE '4%'


UPDATE reporte_general_ventas_temp r
SET componente = e.componente,
    componeexi = COALESCE(b.existencia, 0),
    componedi  = COALESCE(b.buffer, 0)
FROM lista_materiales.estructuras e
         LEFT JOIN control_inventarios.bodegas b ON e.componente = b.item AND b.bodega = 'MTB'
WHERE e.item = r.item
  AND e.componente LIKE '4%';


UPDATE reporte_general_ventas_temp r
SET ped_pendien = pg.ped_pendien
FROM (SELECT pd.item, COALESCE(SUM(pd.cantidad_pendiente), 0) AS ped_pendien
      FROM ordenes_venta.pedidos_detalle pd
      WHERE pd.estado NOT IN ('C', 'V', '-', 'X')
      GROUP BY pd.item) AS pg
WHERE pg.item = r.item;



UPDATE reporte_general_ventas_temp r
SET ped_colocad = pg.ped_colocad
FROM (SELECT pd.item, COALESCE(SUM(pd.cantidad_pendiente + pd.cantidad_despachada), 0) AS ped_colocad
      FROM ordenes_venta.pedidos_detalle pd
      WHERE pd.estado NOT IN ('C', 'V', '-', 'X')
      GROUP BY pd.item) AS pg
WHERE pg.item = r.item;



SELECT r.codigo                                                AS vendedor,
       r.descripcion                                           AS nombre_vendedor,
       i.item,
       fd.descripcion,
       i.unidad_medida,
       i.familia,
       i.linea,
       i.creacion_fecha,
       i.codigo_rotacion,
       i.ultima_venta,
       i.existencia,
       i.peso,
       SUM(fd.cantidad * fd.costo)                             AS vtacosto,
       SUM(fd.cantidad * i.peso)                               AS vtakilo,
       SUM(fd.total_precio - COALESCE(fd.descuento_etatex, 0)) AS vtaprecio_may,
       SUM(fd.cantidad)                                        AS cantidad_may
FROM cuentas_cobrar.facturas_detalle fd
         LEFT JOIN sistema.reglas r ON fd.vendedor = r.codigo AND regla = 'SLSPERS'
         LEFT JOIN control_inventarios.items i ON fd.item = i.item
         LEFT JOIN cuentas_cobrar.clientes c ON fd.cliente = c.codigo
WHERE fd.vendedor <> 'SG'
  AND LEFT(fd.referencia, 1) NOT IN ('X', 'P')
  AND COALESCE(fd.status, '') <> 'V'
  AND (((i.es_fabricado OR i.item IS NULL) AND
        SUBSTRING(i.item FROM 1 FOR 1) IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'B', 'Z')) OR
       (SUBSTRING(i.item FROM 1 FOR 1) NOT IN ('1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'Z', 'B', 'X') AND
        (SUBSTRING(fd.codigo_venta FROM 1 FOR 1) IN ('V', 'D', 'O') OR
         SUBSTRING(fd.codigo_venta FROM 1 FOR 3) IN ('FAE', 'FDE'))) OR SUBSTRING(i.item FROM 1 FOR 2) IN ('1U', '55'))
  AND fd.codigo_venta NOT IN ('GDC', 'GDQ')
  AND LEFT(fd.item, 4) != 'CONO'
  AND fd.fecha BETWEEN '2025-06-01' AND '2025-06-30'
  AND ((fd.item >= '' OR '' = '') AND (fd.item <= '' OR '' = ''))
  AND (i.linea = '' OR '' = '')
  AND (i.familia = '' OR '' = '')
  AND (fd.vendedor = ANY ('{}') OR '{}' = '{}')
  AND ((fd.cliente >= '' OR '' = '') AND (fd.cliente <= '' OR '' = ''))
GROUP BY r.codigo, r.descripcion, i.item, fd.descripcion
