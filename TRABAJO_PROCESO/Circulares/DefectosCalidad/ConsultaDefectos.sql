/*
drop function trabajo_proceso.orden_rollo_consulta_defectos_calidad(p_fecha_inicio date,
                                                                                 p_fecha_fin date,
                                                                                 p_codigo_orden varchar,
                                                                                 p_numero_rollo varchar)
*/

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_consulta_defectos_calidad(p_fecha_inicio date,
                                                                                 p_fecha_fin date,
                                                                                 p_codigo_orden varchar,
                                                                                 p_numero_rollo varchar)
    RETURNS TABLE
            (
                codigo_orden                 VARCHAR,
                numero_rollo                 VARCHAR,
                item                         VARCHAR,
                descripcion                  VARCHAR,
                maquina                      VARCHAR,
                observacion_pesa_crudo       VARCHAR,
                defectos_fabrica_id          varchar,
                defectos_fabrica_descripcion text,
                peso_crudo                   NUMERIC,
                creacion_fecha               DATE
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT rd.codigo_orden,
               rd.numero_rollo,
               o.item,
               i.descripcion,
               o.maquina,
               dt.observacion_pesa_crudo,
               rd.defectos_fabrica_id,
               df.descripcion,
               dt.peso_crudo,
               rd.creacion_fecha
        FROM trabajo_proceso.ordenes_rollos_defectos rd
                 JOIN trabajo_proceso.ordenes o ON rd.codigo_orden = o.codigo_orden
                 JOIN trabajo_proceso.ordenes_rollos_detalle dt
                      ON dt.codigo_orden = o.codigo_orden AND dt.numero_rollo = rd.numero_rollo
                 JOIN control_inventarios.items i ON o.item = i.item
                 JOIN trabajo_proceso.defectos_fabrica df ON rd.defectos_fabrica_id = df.defectos_fabrica_id
        WHERE rd.creacion_fecha BETWEEN p_fecha_inicio AND p_fecha_fin
          AND (p_codigo_orden = '' OR rd.codigo_orden = p_codigo_orden)
          AND (p_numero_rollo = '' OR rd.numero_rollo = p_numero_rollo)
        ORDER BY rd.creacion_fecha, rd.codigo_orden, rd.numero_rollo, rd.defectos_fabrica_id;
END
$function$
;


select *
from trabajo_proceso.orden_rollo_consulta_defectos_calidad('2023-01-01', current_date, '', '') a