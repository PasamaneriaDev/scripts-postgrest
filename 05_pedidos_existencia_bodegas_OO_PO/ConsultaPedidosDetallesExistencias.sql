-- DROP FUNCTION ordenes_venta.pedidos_consulta_existencias_alternativas(varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_consulta_existencias_alternativas(p_numero_pedido character varying, p_cliente character varying, p_codigos_rotacion character varying)
 RETURNS TABLE(numero_pedido character varying, estado character varying, tipo_pedido character varying, cliente character varying, vendedor character varying, nombre_cliente character varying, nombre_vendedor character varying, creacion_fecha date, bodega character varying, item character varying, descripcion character varying, unidad_medida character varying, codigo_rotacion character varying, cantidad_pendiente numeric, exi999mt numeric, exi999yd numeric, exi999pz numeric, exi100mt numeric, exi100yd numeric, exi100pz numeric, exipntovtamt numeric, exipntovtayd numeric, exipntovtapz numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        WITH cte AS (SELECT t.numero_pedido,
                            t.item,
                            t.cantidad_pendiente,
                            t.cantidad_despacho,
                            t.cliente,
                            t.estado,
                            t.tipo_pedido,
                            t.vendedor,
                            t.creacion_fecha,
                            t.bodega,
                            t.descripcion
                     FROM (SELECT DISTINCT pd.item
                           FROM ordenes_venta.pedidos_detalle pd
                                    JOIN control_inventarios.items it ON pd.item = it.item
                           WHERE (pd.numero_pedido = p_numero_pedido OR p_numero_pedido = '')
                             AND (pd.cliente = p_cliente OR p_cliente = '')
                             AND it.codigo_rotacion IN
                                 (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p_codigos_rotacion FROM 2), ',')))
                             AND LEFT(pd.cliente, 2) <> '99'
                             AND pd.cantidad_pendiente > 0
                             AND pd.tipo_pedido <> 'B'
                             AND LEFT(pd.item, 1) NOT IN ('1', '4', 'B')
                           ORDER BY pd.item) AS ipd
                              CROSS JOIN LATERAL control_inventarios.item_consulta_compromiso_cliente(ipd.item) AS t
                     WHERE t.cantidad_despacho <> t.cantidad_pendiente
                       AND NOT t.tiene_vencimiento)
        SELECT t.numero_pedido,
               t.estado,
               t.tipo_pedido,
               t.cliente,
               t.vendedor,
               cc.nombre                      AS nombre_cliente,
               v.nombres                      AS nombre_vendedor,
               t.creacion_fecha,
               t.bodega,
               t.item,
               t.descripcion,
               it.unidad_medida,
               it.codigo_rotacion,
               ROUND(t.cantidad_pendiente, 2) AS cantidad_pendiente,
               ROUND(control_inventarios.obtiene_existencia_item_bodega('999', LEFT(t.item, -1) ||
                                                                               4),
                     2)                       AS exi999mt,
               ROUND(control_inventarios.obtiene_existencia_item_bodega('999', LEFT(t.item, -1) ||
                                                                               5),
                     2)                       AS exi999yd,
               ROUND(control_inventarios.obtiene_existencia_item_bodega('999', LEFT(t.item, -1) ||
                                                                               0),
                     2)                       AS exi999pz,

               ROUND(control_inventarios.obtiene_existencia_item_bodega('100', LEFT(t.item, -1) ||
                                                                               4),
                     2)                       AS exi100mt,
               ROUND(control_inventarios.obtiene_existencia_item_bodega('100', LEFT(t.item, -1) ||
                                                                               5),
                     2)                       AS exi100yd,
               ROUND(control_inventarios.obtiene_existencia_item_bodega('100', LEFT(t.item, -1) ||
                                                                               0),
                     2)                       AS exi100pz,

               ROUND(control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(t.item, -1) || 4),
                     2)                       AS exipntovtamt,
               ROUND(control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(t.item, -1) || 5),
                     2)                       AS exipntovtayd,
               ROUND(control_inventarios.obtiene_total_existencia_item_punto_venta(LEFT(t.item, -1) || 0),
                     2)                       AS exipntovtapz
        FROM cte t
                 JOIN control_inventarios.items it ON t.item = it.item
                 JOIN cuentas_cobrar.clientes cc ON t.cliente = cc.codigo
                 LEFT JOIN ordenes_venta.vendedores v ON t.vendedor = v.codigo
        WHERE (t.numero_pedido = p_numero_pedido OR p_numero_pedido = '')
          AND (t.cliente = p_cliente OR p_cliente = '')
          AND it.codigo_rotacion IN
              (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p_codigos_rotacion FROM 2), ',')))
        ORDER BY t.creacion_fecha DESC;
END
$function$
;
