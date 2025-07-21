/*
 drop function puntos_venta.requerimientos_consulta_modifica_cantidad(p_requerimiento varchar)
*/

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_consulta_modifica_cantidad(p_requerimiento varchar)
    RETURNS table
            (
                nro_requerimiento   varchar,
                item                varchar,
                descripcion         varchar,
                unidad_medida       varchar,
                numero_decimales    numeric,
                cantidad_solicitada varchar,
                existencias         numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_bodegas varchar;
BEGIN
    SELECT p.alfa
    INTO v_bodegas
    FROM sistema.parametros p
    WHERE p.modulo_id = 'PVENTAS'
      AND p.codigo = 'BODEGAS_REQUERIMIENTOS';

    v_bodegas = '{' || v_bodegas || '}';

    RETURN QUERY
        SELECT rg.nro_requerimiento,
               rg.item,
               i.descripcion,
               i.unidad_medida,
               i.numero_decimales,
               rg.cantidad_solicitada,
               SUM(b.existencia) existencias
        FROM trabajo_proceso.requerimiento_guia rg
                 JOIN control_inventarios.items i ON rg.item = i.item
                 JOIN control_inventarios.bodegas b ON b.item = i.item AND b.bodega = ANY (v_bodegas::TEXT[])
        WHERE rg.nro_requerimiento = p_requerimiento
        GROUP BY rg.nro_requerimiento, i.item;
END;
$function$
;
