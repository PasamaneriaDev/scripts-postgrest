-- DROP FUNCTION trabajo_proceso.tintoreria_consulta_registro_produccion(int4, date, date);

CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_consulta_registro_produccion(p_tintoreria_control_calidad_id integer,
                                                                                   p_fecha_inicio date,
                                                                                   p_fecha_fin date)
    RETURNS TABLE
            (
                codigo_orden                  character varying,
                item                          character varying,
                descripcion                   character varying,
                cantidad_planificada          numeric,
                cantidad_fabricada            numeric,
                maquina                       character varying,
                observaciones                 character varying,
                estado_lote                   character varying,
                tono                          character varying,
                gramaje                       numeric,
                ancho                         numeric,
                encogimiento_ancho            numeric,
                encogimiento_largo            numeric,
                solidez_humedo                character varying,
                solidez_frote                 character varying,
                kilos_prueba                  numeric,
                defectos_observados           character varying,
                creacion_usuario              character varying,
                creacion_fecha                timestamp WITHOUT TIME ZONE,
                tintoreria_control_calidad_id integer
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT tcc.codigo_orden,
               o.item,
               i.descripcion,
               o.cantidad_planificada,
               o.cantidad_fabricada,
               o.maquina,
               tcc.observaciones,
               tcc.estado_lote,
               tcc.tono,
               tcc.gramaje,
               tcc.ancho,
               tcc.encogimiento_ancho,
               tcc.encogimiento_largo,
               tcc.solidez_humedo,
               tcc.solidez_frote,
               tcc.kilos_prueba,
               tcc.defectos_observados,
               tcc.creacion_usuario,
               tcc.creacion_fecha,
               tcc.tintoreria_control_calidad_id
        FROM trabajo_proceso.tintoreria_control_calidad tcc
                 JOIN trabajo_proceso.ordenes o
                      ON tcc.codigo_orden = o.codigo_orden
                 JOIN control_inventarios.items i
                      ON o.item = i.item
        WHERE (p_tintoreria_control_calidad_id = 0 OR
               tcc.tintoreria_control_calidad_id = p_tintoreria_control_calidad_id)
          AND tcc.creacion_fecha::DATE BETWEEN p_fecha_inicio AND p_fecha_fin
        ORDER BY tcc.creacion_fecha;
END;
$function$
;
