-- DROP FUNCTION control_inventarios.item_consulta_rutas_con_proceso(p_item character varying,p_orden character varying,p_centro character varying,p_operacion character varying)

CREATE OR REPLACE FUNCTION control_inventarios.item_consulta_rutas_con_proceso(p_item character varying,
                                                                               p_orden character varying,
                                                                               p_centro character varying,
                                                                               p_operacion character varying)
    RETURNS TABLE
            (
                ruta          character varying,
                operacion     character varying,
                centro        character varying,
                proceso       character varying,
                tiempo        numeric,
                fecha_inicial date,
                hora_inicial  time,
                fecha_final   date,
                hora_final    time,
                es_buscado    boolean
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN

    RETURN QUERY
        SELECT r.ruta,
               r.operacion,
               r.centro,
               r.proceso,
               round(hr.tiempo, 2)  AS tiempo,
               hr.fecha_inicial::date AS fecha_inicial,
               hr.fecha_inicial::time AS hora_inicial,
               hr.fecha_final::date   AS fecha_final,
               hr.fecha_final::time   AS hora_final,
               CASE
                   WHEN hr.centro = p_centro AND hr.operacion = p_operacion THEN TRUE
                   ELSE FALSE END     AS es_buscado
        FROM rutas.rutas r
                 JOIN control_inventarios.items i
                      ON i.ruta = r.ruta
                 LEFT JOIN trabajo_proceso.hoja_ruta hr
                           ON hr.centro = r.centro AND hr.operacion = r.operacion AND
                              hr.codigo_orden = p_orden
        WHERE i.item = p_item;
END;
$function$
;