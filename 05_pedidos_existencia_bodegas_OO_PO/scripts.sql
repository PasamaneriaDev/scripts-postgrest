-- Pantalla que permita ver las ordenes PO OO, donde el detalle de items pueda ser alternado la bodega
-- es decir, ofrecer la alternativa de visualizar la cantidad disponible en otras bodegas para el mismo
-- Ademas totalizar si es punto de  venta (tabla de bodegas), y si da click en el totalizado, enviar a ventana modal

SELECT *
FROM ordenes_venta.pedidos_cabecera;



SELECT *
FROM ordenes_venta.pedidos_detalle;



SELECT *
FROM control_inventarios.bodegas
WHERE bodega IN ('999', '100')



SELECT pd.numero_pedido,
       pd.estado,
       pd.tipo_pedido,
       pd.cliente,
       cc.nombre,
       pd.creacion_fecha,
       pd.bodega,
       pd.item,
       pd.descripcion,
       it.unidad_medida,
       it.codigo_rotacion,
       pd.cantidad_pendiente,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, 13) || 4)     AS exi999mt,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, 13) || 5)     AS exi999yd,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, 13) || 0)     AS exi999pz,

       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, 13) || 4)     AS exi100mt,
       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, 13) || 5)     AS exi100yd,
       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, 13) || 0)     AS exi100pz,

       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, 13) || 4) +
       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, 13) || 5) +
       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, 13) || 0) AS exipuntovta
FROM ordenes_venta.pedidos_detalle pd
         JOIN control_inventarios.items it ON pd.item = it.item
         JOIN cuentas_cobrar.clientes cc ON pd.cliente = cc.codigo
WHERE LEFT(cliente, 2) <> '99'
  AND cantidad_pendiente > 0
  AND tipo_pedido <> 'B'
  AND TRIM(it.codigo_rotacion) NOT IN ('AA', 'AB', 'EE')
  AND LEFT(pd.item, 1) NOT IN ('1', '4', 'B')
ORDER BY pd.item;

#   Cliente Fecha   Bodega  Item    Descripcion Unidad  CO  Cantidad    Exis.999 MT    Exis.999 YD    Exis.999 PZ    Exis.100 MT    Exis.100 YD    Exis.100 PZ    Exis.Pntos.vta

10%, 15%, 10%, 5%, 10%, 15%, 5%, 5%, 5%, 5%, 5%, 5%, 5%, 5%, 5%, 5%

SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE LEFT(cliente, 2) = '99'


SELECT *
FROM cuentas_cobrar.clientes
WHERE LEFT(codigo, 2) = '99'



SELECT *
FROM control_inventarios.bodegas
WHERE
  AND item = '17600046606011'


SELECT control_inventarios.obtiene_existencia_item_bodega('999', 'a')


SELECT * --COALESCE(b.existencia, 0) AS existencia
FROM control_inventarios.bodegas b
         JOIN control_inventarios.id_bodegas ib
              ON b.bodega = ib.bodega
WHERE ib.es_punto_venta
  AND LEFT(item, 13) = '1117006660601'


SELECT control_inventarios.obtiene_existencia_total_item_punto_venta('11170066606011')
           "SELECT t.numero_pedido, " + _
"       estado, " + _
"       tipo_pedido, " + _
"       cliente, " + _
"       nombre, " + _
"       creacion_fecha, " + _
"       bodega, " + _
"       item, " + _
"       descripcion, " + _
"       unidad_medida, " + _
"       codigo_rotacion, " + _
"       cantidad_pendiente, " + _
"       exi999mt, " + _
"       exi999yd, " + _
"       exi999pz, " + _
"       exi100mt, " + _
"       exi100yd, " + _
"       exi100pz, " + _
"       exipuntovta " + _
"FROM ordenes_venta.pedidos_consulta_existencias_alternativas('999', '11170066606011', '') AS t "

SELECT *
FROM ordenes_venta.pedidos_consulta_existencias_alternativas('999', '11170066606011', '')


SELECT b.bodega,
       control_inventarios.obtiene_existencia_item_bodega(b.bodega, LEFT(b.item, 13) || 4) AS eximt,
       control_inventarios.obtiene_existencia_item_bodega(b.bodega, LEFT(b.item, 13) || 5) AS exiyd,
       control_inventarios.obtiene_existencia_item_bodega(b.bodega, LEFT(b.item, 13) || 0) AS exipz
FROM control_inventarios.bodegas b
         JOIN control_inventarios.id_bodegas ib
              ON b.bodega = ib.bodega
WHERE b.item IN (LEFT('11170066606011', 13) || 4, LEFT('11170066606011', 13) || 5, LEFT('11170066606011', 13) || 0)
  AND ib.es_punto_venta



WITH cte AS (SELECT b.bodega,
                    control_inventarios.obtiene_existencia_item_bodega(b.bodega,
                                                                       LEFT('28260065306445', 13) || 4)           AS eximt,
                    control_inventarios.obtiene_existencia_item_bodega(b.bodega, LEFT('28260065306445', 13) ||
                                                                                 5)                               AS exiyd,
                    control_inventarios.obtiene_existencia_item_bodega(b.bodega, LEFT('28260065306445', 13) ||
                                                                                 0)                               AS exipz
             FROM control_inventarios.id_bodegas b
             WHERE es_punto_venta)
SELECT t.bodega, t.eximt, t.exipz, t.exiyd
FROM cte AS t
WHERE NOT (eximt = 0 AND exiyd = 0 AND exipz = 0);



SELECT bodega, descripcion, eximt, exipz, exiyd
FROM control_inventarios.obtiene_existencias_item_puntos_venta_mt_yd_pz('28260065306445')


SELECT *
FROM control_inventarios.id_bodegas

SELECT *
FROM ordenes_venta.pedidos_detalle


SELECT *
FROM ordenes_venta.vendedores "SELECT numero_pedido, " + _
  "       estado, " + _
  "       tipo_pedido, " + _
  "       cliente, " + _
  "       nombre_cliente, " + _
  "       nombre_vendedor, " + _
  "       creacion_fecha, " + _
  "       bodega, " + _
  "       item, " + _
  "       descripcion, " + _
  "       unidad_medida, " + _
  "       codigo_rotacion, " + _
  "       cantidad_pendiente, " + _
  "       exi999mt, " + _
  "       exi999yd, " + _
  "       exi999pz, " + _
  "       exi100mt, " + _
  "       exi100yd, " + _
  "       exi100pz, " + _
  "       exipntovtamt, " + _
  "       exipntovtayd, " + _
  "       exipntovtapz " + _

SELECT REGEXP_SPLIT_TO_TABLE(',valor2,valor3', ',') AS value;

SELECT tipos
FROM (SELECT UNNEST(STRING_TO_ARRAY(',valor2,valor3', ',')) AS tipos) AS subquery
WHERE tipos <> '';



SELECT *
FROM control_inventarios.id_bodegas
WHERE bodega IN (UNNEST(STRING_TO_ARRAY('')))


SELECT *
FROM
    ordenes_venta.pedidos_consulta_existencias_alternativas('', '', 'OO,PO')



CREATE INDEX idx_items_item_codigo_rotacion ON control_inventarios.items (item, codigo_rotacion);

SELECT SUBSTRING('example_string' FROM 2);


SELECT LEFT('123', -1) || 1


WITH cte AS (SELECT t.numero_pedido, t.item, t.cantidad_pendiente, t.cantidad_despacho, t.cliente
             FROM (SELECT DISTINCT pd.item
                   FROM ordenes_venta.pedidos_detalle pd
                            JOIN control_inventarios.items it ON pd.item = it.item
                   WHERE it.codigo_rotacion IN
                         (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(',OO,PO' FROM 2), ',')))
                     AND LEFT(pd.cliente, 2) <> '99'
                     AND pd.cantidad_pendiente > 0
                     AND pd.tipo_pedido <> 'B'
                     AND LEFT(pd.item, 1) NOT IN ('1', '4', 'B')
                   ORDER BY pd.item) AS ipd
                      CROSS JOIN LATERAL ordenes_venta.item_disponible_despachar(ipd.item) AS t
             WHERE t.cantidad_despacho <> t.cantidad_pendiente
               AND NOT t.tiene_vencimiento)
SELECT t.numero_pedido,
       pd.estado,
       pd.tipo_pedido,
       pd.cliente,
       pd.vendedor,
       cc.nombre                                                                             AS nombre_cliente,
       v.nombres                                                                             AS nombre_vendedor,
       pd.creacion_fecha,
       pd.bodega,
       pd.item,
       pd.descripcion,
       it.unidad_medida,
       it.codigo_rotacion,
       pd.cantidad_pendiente,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, -1) ||
                                                                 4)                          AS exi999mt,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, -1) ||
                                                                 5)                          AS exi999yd,
       control_inventarios.obtiene_existencia_item_bodega('999', LEFT(pd.item, -1) ||
                                                                 0)                          AS exi999pz,

       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, -1) ||
                                                                 4)                          AS exi100mt,
       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, -1) ||
                                                                 5)                          AS exi100yd,
       control_inventarios.obtiene_existencia_item_bodega('100', LEFT(pd.item, -1) ||
                                                                 0)                          AS exi100pz,

       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, -1) || 4) AS exipntovtamt,
       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, -1) || 5) AS exipntovtayd,
       control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(pd.item, -1) || 0) AS exipntovtapz
FROM cte t
         JOIN ordenes_venta.pedidos_detalle pd
              ON t.numero_pedido = pd.numero_pedido
                  AND t.item = pd.item
                  AND t.cliente = pd.cliente
         JOIN control_inventarios.items it ON pd.item = it.item
         JOIN cuentas_cobrar.clientes cc ON pd.cliente = cc.codigo
         left JOIN ordenes_venta.vendedores v ON pd.vendedor = v.codigo
;




SELECT *
FROM ordenes_venta.item_disponible_despachar('28260065918605');

select *
from ordenes_venta.exisubic



select *
from ordenes_venta.pedidos_detalle
where numero_pedido in (
    '4053909',
'4052195',
'101035274'

    )
and item =  '28260065918605'




select *
from ordenes_venta.vendedores
where codigo
    in (
'AL', --
'CO', --
'MM', --
'PD', --
'SC',
'XM'

   )


SELECT codigo, COUNT(*) AS total
FROM (VALUES
    ('AL'), ('AL'), ('CO'), ('CO'), ('CO'), ('CO'), ('CO'), ('SC'), ('MM'), ('MM'), ('MM'), ('MM'), ('MM'), ('MM'), ('MM'), ('MM'),
    ('XM'), ('XM'), ('XM'), ('XM'), ('SC'), ('SC'), ('SC'), ('SC'), ('XM'), ('SC'), ('MM'), ('MM'), ('XM'), ('XM'), ('XM'), ('XM'),
    ('XM'), ('XM'), ('XM'), ('XM'), ('XM'), ('PD'), ('PD'), ('PD'), ('PD'), ('PD'), ('PD'), ('MM'), ('PD'), ('MM')
) AS codes(codigo)
GROUP BY codigo
ORDER BY codigo;

select 46 - 26



  SELECT nro_requerimiento, centro_costo, nombre_centro_costo, item, descripcion, fecha_solicitud, fecha_requerimiento,
    cantidad_solicitada, comentario, cantidad_entragada, fecha_entregada, fecha_recibido_almacen, estado
  FROM puntos_venta.requerimientos_consulta('V65','2018-12-04','2024-11-21','','')



SELECT *
FROM sistema.menu
WHERE moduloid = 19


INSERT INTO sistema.menu (menuid, titulo, nombre, orden, padreid, moduloid, esmenu, migracion, padre, path_web)
VALUES (1095, 'Pedidos WEB', 'ReportesPedidosdelaWeb', 28, 804, 19, FALSE, 'NO', NULL, NULL);



