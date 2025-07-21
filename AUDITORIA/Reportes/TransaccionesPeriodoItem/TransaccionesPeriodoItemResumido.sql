-- DROP FUNCTION auditoria.reporte_ventas_x_lugar(p_periodo varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_transacciones_x_periodo_item_resumido(p_periodo_ini varchar,
                                                                                   p_periodo_fin varchar,
                                                                                   p_item_ini varchar,
                                                                                   p_item_fin varchar,
                                                                                   p_tipo_item varchar,
                                                                                   p_fabricacion varchar)
    RETURNS TABLE
            (
                item               varchar,
                descripcion        varchar,
                unidad_medida      varchar,
                codigo_rotacion    varchar,
                existencias        numeric,
                cantidad_vendida   numeric,
                valor_vendido      numeric,
                cantidad_recibida  numeric,
                valor_recibido     numeric,
                cantidad_consumida numeric,
                valor_consumido    numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT i.item,
               i.descripcion,
               i.unidad_medida,
               i.codigo_rotacion,
               SUM(i.existencia)                                            existencias,
               SUM(ih.cantidad_vendida_periodo)                             cantidad_vendida,
               SUM(ih.valor_vendido_periodo)                                valor_vendido,
               SUM(ih.cantidad_recibida_periodo)                            cantidad_recibida,
               SUM(ih.valor_recibido_periodo)                               valor_recibido,
               SUM(ih.cantidad_usada_periodo - ih.cantidad_vendida_periodo) cantidad_consumida,
               SUM(ih.valor_usado_periodo - ih.valor_vendido_periodo)       valor_consumido
        FROM control_inventarios.items_historico ih
                 JOIN control_inventarios.items i ON ih.item = i.item
        WHERE ih.periodo BETWEEN p_periodo_ini AND p_periodo_fin
          AND ih.nivel = 'ILOC'
          and i.es_stock
          AND ((p_item_ini = '' AND p_item_fin = '') OR ih.item BETWEEN p_item_ini AND p_item_fin)
          AND (p_tipo_item = 'TODO' OR (p_tipo_item = 'VENTA' AND i.es_vendible) OR
               (p_tipo_item = 'NO VENTA' AND NOT i.es_vendible))
          AND (p_fabricacion = 'TODO' OR (p_fabricacion = 'INTERNA' AND i.es_fabricado) OR
               (p_fabricacion = 'EXTERNA' AND NOT i.es_fabricado))
          AND (ih.cantidad_vendida_periodo <> 0 OR ih.valor_vendido_periodo <> 0 OR
               ih.cantidad_recibida_periodo <> 0 OR ih.valor_recibido_periodo <> 0 OR
               ih.cantidad_usada_periodo <> 0 OR ih.valor_usado_periodo <> 0)
        GROUP BY i.item;
END ;
$function$
;


