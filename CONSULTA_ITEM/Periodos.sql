-- DROP FUNCTION control_inventarios.periodos_por_item_nivel(p_item varchar, p_nivel varchar)

CREATE OR REPLACE FUNCTION control_inventarios.periodos_por_item_nivel(p_item varchar, p_nivel varchar)
    RETURNS TABLE
            (
                periodo                   varchar,
                nivel                     varchar,
                bodega                    varchar,
                ubicacion                 varchar,
                existencia                numeric,
                transito                  numeric,
                cantidad_recibida_periodo numeric,
                valor_recibido_periodo    numeric,
                cantidad_usada_periodo    numeric,
                valor_usado_periodo       numeric,
                cantidad_vendida_periodo  numeric,
                valor_vendido_periodo     numeric,
                costo_promedio            numeric,
                buffer                    numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    return query
    SELECT ih.periodo,
           ih.nivel,
           ih.bodega,
           ih.ubicacion,
           ih.existencia,
           ih.transito,
           ih.cantidad_recibida_periodo,
           ih.valor_recibido_periodo,
           ih.cantidad_usada_periodo,
           ih.valor_usado_periodo,
           ih.cantidad_vendida_periodo,
           ih.valor_vendido_periodo,
           ih.costo_promedio,
           ih.buffer
    FROM control_inventarios.items_historico ih
    WHERE ih.item = p_item
      AND (p_nivel = '' or ih.nivel = p_nivel)
    ORDER BY ih.periodo, ih.nivel, ih.bodega;
END ;
$function$
;


select *
from control_inventarios.periodos_por_item_nivel('12470046606013', 'ICQTY')