/*
19|110887|157
20|111004|158
21|111128|159
22|200570|160
23|200570|161
24|108001|162
*/

BEGIN;
SELECT *
FROM ordenes_venta.proforma_genera_x_toma_inventario(24, '001', '3191');

ROLLBACK;
-- 51722202,51722203
/*********************************/
SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido IN ('51722207', '51722208');

SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE numero_pedido IN ('51722207', '51722208');

/*****************************/
SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido IN ('51722206');

SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE numero_pedido IN ('51722206');

SELECT aj.*, p.precio, (aj.cantidad_ajuste * p.precio) AS total
FROM control_inventarios.ajustes aj
         JOIN control_inventarios.precios p ON aj.item = p.item AND p.tipo = 'MAY'
WHERE aj.bodega = '161';

SELECT *
FROM sistema.interface
WHERE modulo = 'ORDENES DE VENTA'
  AND fecha = CURRENT_DATE::text;

SELECT *
FROM sistema.interface
WHERE modulo = 'AUDITORIA'
  AND fecha = CURRENT_DATE::text;

/*******************************/

SELECT *
FROM control_inventarios.precios
WHERE item = '7025026624305FU';

SELECT *
FROM control_inventarios.items
WHERE item = '7025026624305FU';

-- 2828006554004F

ROLLBACK;
SELECT AJ.*
FROM control_inventarios.ajustes aj
         LEFT JOIN control_inventarios.precios p ON aj.item = p.item
    AND p.tipo = 'PVP'
WHERE aj.bodega = '162'
  AND p.item IS NULL;



SELECT *
FROM control_inventarios.ajustes a
WHERE a.bodega = '162'
  AND a.tipo = 'T'
  AND a.status = '';

SELECT *
FROM control_inventarios.ajustes a
WHERE documento = '0000162PVP';

SELECT *
FROM control_inventarios.bodegas
WHERE bodega = '157';

INSERT INTO control_inventarios.bodegas (bodega, item, existencia, transito, buffer, pedidos_clientes,
                                         asignacion_produccion, ordenes_compra, ordenes_trabajo,
                                         asignacion_distribucion, en_proceso_despacho, primera_recepcion, ultima_venta,
                                         ultima_recepcion, ultima_compra, ultimo_ingreso_transferencia,
                                         ultimo_egreso_transferencia, valor_usado_periodo, valor_vendido_periodo,
                                         cantidad_usada_periodo, cantidad_vendida_periodo, valor_recibido_periodo,
                                         cantidad_recibida_periodo, cantidad_vendida_ano, valor_vendido_ano,
                                         cantidad_usada_ano, valor_usado_ano, cantidad_recibida_ano, valor_recibido_ano,
                                         fecha_redimension_buffer, cuenta_inventarios, cuenta_compras, cuenta_ajuste,
                                         codigo_integracion, ciclo_conteo, fecha_conteo, corte_conteo, fisico_conteo,
                                         conteo_grabado, auditoria_conteo, creacion_usuario, creacion_fecha,
                                         creacion_hora, codigo_proveedor, dias_entrega_proveedor, fecha_migrada,
                                         migracion, fecha_redimension_cobertura, auditoria_id, comprometido_pedido)
VALUES ('162', '27A0024491664AF', 100.00000, 0.000, 0.000, 0.000, 0.00000, 0.00000, 0.000, 0.000, 0.000, NULL,
        '2025-01-24', '2015-11-16', NULL, '2025-01-24', NULL, 0.00, 0.00, 0.00000, 0.00000, 0.000, 0.00000, 100.00000,
        254.15, 0.00000, 0.00, 0.00000, 0.000, '2021-08-04', '11304010100000000', '21103000000000000', '', 'PRT', 0,
        NULL, 0.000, 0.000, FALSE, FALSE, '', NULL, '', '', 0, '2019-01-01', 'NO', NULL, 19736563, 0.000),
       ('162', '1C270066939251', 120.00000, 0.000, 0.000, 0.000, 0.00000, 0.00000, 0.000, 0.000, 0.000, NULL,
        '2025-01-24', '2015-11-16', NULL, '2025-01-24', NULL, 0.00, 0.00, 0.00000, 0.00000, 0.000, 0.00000, 100.00000,
        254.15, 0.00000, 0.00, 0.00000, 0.000, '2021-08-04', '11304010100000000', '21103000000000000', '', 'PRT', 0,
        NULL, 0.000, 0.000, FALSE, FALSE, '', NULL, '', '', 0, '2019-01-01', 'NO', NULL, 19736563, 0.000);



INSERT INTO control_inventarios.precios (item, tipo, precio, calculado_formula, ultima_actualizacion, pvp_base,
                                         creacion_usuario, creacion_fecha, creacion_hora, fecha_migrada, pvp_99,
                                         migracion, auditoria_id)
VALUES ('27A0024491664AF', 'MAY', 2.5600, FALSE, '2009-06-25', 4.25, '2865', '2009-06-25', '11:49:16', '2017-06-01',
        0.00,
        'SI', 1857162);

, con precio: MAY

SELECT *
FROM control_inventarios.items
WHERE item LIKE '1%';



SELECT *
FROM control_inventarios.ajustes a
         JOIN control_inventarios.items i ON a.item = i.item
         LEFT JOIN control_inventarios.bodegas b ON b.item = a.item AND b.bodega = a.bodega
WHERE a.bodega = '157'
  AND a.cantidad_ajuste <= b.existencia

SELECT usuarios_activos.usuario, usuarios.nombres
FROM sistema.usuarios_activos
         INNER JOIN sistema.usuarios ON sistema.usuarios_activos.usuario = sistema.usuarios.codigo
WHERE TRIM(computador) = 'ANALISTA3'
  AND estado = 'ACTIVO'



SELECT a.item,
       i.descripcion,
       COALESCE(b.existencia, 0) - a.cantidad_ajuste AS cantidad,
       b.existencia,
       a.cantidad_ajuste,
       i.costo_promedio,
       p.precio,
       'VFQ'                                         AS codigo_venta,
       'PRT'                                         AS codigo_inventario,
       TRUE                                          AS es_stock,
       TRUE                                          AS tiene_iva,
       p.tipo                                        AS tipo_precio,
       a.bodega,
       'B'                                           AS tipo_pedido
FROM control_inventarios.ajustes a
         JOIN control_inventarios.items i ON a.item = i.item
         JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = 'PVP'
         LEFT JOIN control_inventarios.bodegas b ON b.item = a.item AND b.bodega = a.bodega
WHERE a.bodega = '162'
  AND a.tipo = 'T'
  AND a.status = ''
  AND a.cantidad_ajuste < COALESCE(b.existencia, 0)


SELECT *
FROM control_inventarios.ajustes a
WHERE a.bodega = '162'
  AND a.tipo = 'T'
  AND a.status = '';


SELECT *
FROM control_inventarios.bodegas b
WHERE b.bodega = '162' -- BA02200005B

SELECT *
FROM control_inventarios.items
WHERE item LIKE 'BA%'

SELECT *
FROM ordenes_venta.pedidos_cabecera
ORDER BY creacion_fecha DESC;


SELECT numero_pedido, terminal, *
FROM sistema.parametros_almacenes a
WHERE bodega IN ('101', '001');
101037303
4057361


SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido = '4057362';
SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE numero_pedido = '4057362';

BEGIN;
SELECT ordenes_venta.proforma_genera_x_toma_inventario(24,
                                                       '101',
                                                       '3191');
ROLLBACK;

BEGIN;
SELECT sistema.pedido_numero_obtener('101');

SELECT numero_pedido, numero_pedido + 1
FROM sistema.parametros_almacenes
WHERE bodega = '001' -- 101037303|101037304
  AND terminal = '01'



