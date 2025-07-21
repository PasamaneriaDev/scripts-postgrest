-- DROP FUNCTION control_inventarios.item_consulta_rutas_con_proceso(p_item character varying,p_orden character varying,p_centro character varying,p_operacion character varying)

CREATE OR REPLACE FUNCTION control_inventarios.items_proximos_po_ps()
    RETURNS table
            (
                item            character varying,
                descripcion     character varying,
                codigo_rotacion character varying,
                creacion_fecha  date
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT i.item, i.descripcion, i.codigo_rotacion, i.creacion_fecha
        FROM control_inventarios.items i
        WHERE i.proximo_po_ps;
END;
$function$
;