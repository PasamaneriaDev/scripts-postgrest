/*
 drop function trabajo_proceso.tarjetas_circulares(character varying);
 */

CREATE OR REPLACE FUNCTION trabajo_proceso.ordenes_rollos_defectos_inserta(p_datajs character varying)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN

    INSERT INTO trabajo_proceso.ordenes_rollos_defectos (codigo_orden,
                                                         numero_rollo,
                                                         defectos_fabrica_id,
                                                         creacion_usuario)
    SELECT LEFT(a.codigo_orden_rollo, LENGTH(a.codigo_orden_rollo) - 3),
           RIGHT(a.codigo_orden_rollo, 3),
           a.defectos_fabrica_id,
           a.creacion_usuario
    FROM JSON_TO_RECORDSET(p_datajs::json) a (codigo_orden_rollo text, defectos_fabrica_id text, creacion_usuario text);

END;
$function$
;
