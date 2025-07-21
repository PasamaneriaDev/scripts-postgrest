SELECT e.componente,
       i.descripcion,
       i.codigo_rotacion,
       e.item,
       e.cantidad,
       e.factor_desperdicio,
       e.fecha_inicial,
       e.fecha_final,
       i.unidad_medida,
       i.costo_estandard_mp,
       i.costo_estandard_mo,
       i.costo_estandard_gf,
       i.es_fantasma,
       i.tiene_estructura
FROM lista_materiales.estructuras E
         INNER JOIN
     control_inventarios.items I ON e.componente = i.item
WHERE e.item = '10160006000133'
ORDER BY e.item, e.componente, i.descripcion



SELECT x1.numero_pedido,
       x1.fecha_pedido,
       x1.cliente,
       c.nombre,
       x1.bodega,
       x1.cantidad_pendiente,
       x1.cantidad_despacho
FROM ordenes_venta.item_disponible_despachar('33620035606015') x1
         JOIN cuentas_cobrar.clientes c ON x1.cliente = c.codigo
         JOIN ordenes_venta.pedidos_detalle pd
              ON pd.numero_pedido = x1.numero_pedido AND pd.item = x1.item AND pd.cliente = x1.cliente


SELECT bodega,
       cliente_ubic,
       cliente,
       numero_pedido,
       fecha_pedido,
       fecha_entrega,
       item,
       cantidad_pendiente,
       cantidad_despacho,
       es_dudoso,
       status,
       verifica_vencimiento,
       tiene_vencimiento,
       protestado,
       nombre_cliente,
       vendedor,
       fecha_original_pedido,
       fecha_ultimo_despacho
FROM control_inventarios.item_consulta_compromiso_cliente('145800M6606011')



SELECT * FROM ordenes_venta.item_disponible_despachar('145800M6606011')

select * from control_inventarios.obtiene_existencia_item_bodega('145800M6606011', '10160006000133')













SELECT *
FROM rutas.rutas r
JOIN control_inventarios.items i
ON i.ruta = r.ruta
WHERE i.item = '12470046606013';

SELECT * FROM trabajo_proceso.hoja_ruta hr
WHERE hr.codigo_orden = '1C-F6066301422'
AND hr.centro =
AND hr.operacion =