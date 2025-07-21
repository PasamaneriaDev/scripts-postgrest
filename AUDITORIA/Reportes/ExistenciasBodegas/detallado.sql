-- DROP FUNCTION auditoria.reporte_existencias_bodega_detallado(varchar, varchar, varchar, varchar, bool, bool, bool, bool, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_existencias_bodega_detallado(p_bodegas character varying,
                                                                          p_item_inicial character varying,
                                                                          p_item_final character varying,
                                                                          p_periodo character varying,
                                                                          p_negativos boolean, p_por_ubicac boolean,
                                                                          p_con_cero boolean, p_val_costo boolean,
                                                                          p_ubicacion character varying,
                                                                          p_existencia character varying,
                                                                          p_tipo character varying,
                                                                          p_articulo character varying)
    RETURNS TABLE
            (
                item          character varying,
                descripcion   character varying,
                es_vendible   boolean,
                es_fabricado  boolean,
                es_comprado   boolean,
                costo_promedio numeric,
                unidad_medida character varying,
                existencia    numeric,
                valor         numeric,
                bodega        character varying,
                descripcion_bodega character varying,
                ubicacion     character varying,
                transito      numeric,
                comprometido  numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    PERFORM auditoria.genera_existencia_bodega_temp(p_bodegas, p_item_inicial, p_item_final, p_periodo, p_negativos,
                                                    p_por_ubicac, p_con_cero, p_val_costo, p_ubicacion, p_existencia,
                                                    p_tipo, p_articulo);

    RETURN QUERY
        SELECT tb.item,
               tb.descripcion,
               tb.es_vendible,
               tb.es_fabricado,
               tb.es_comprado,
               tb.costo_promedio,
               tb.unidad_medida,
               tb.existencia,
               tb.valor,
               tb.bodega,
               tb.descripcion_bodega,
               tb.ubicacion,
               tb.transito,
               tb.comprometido
        FROM _temp_exist_bod tb;
END;
$function$
;
