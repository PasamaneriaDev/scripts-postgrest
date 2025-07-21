-- DROP FUNCTION trabajo_proceso.cierre_ordenes_produccion(text, text, numeric, text);

CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_control_calidad_merge(p_datajs character varying,
                                                                            p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RAISE NOTICE 'datajson: %', p_datajs;
    INSERT INTO trabajo_proceso.tintoreria_control_calidad (codigo_orden, observaciones, estado_lote, tono, gramaje,
                                                            ancho,
                                                            encogimiento_ancho, solidez_humedo, solidez_frote,
                                                            kilos_prueba,
                                                            defectos_observados, creacion_usuario, encogimiento_largo)
    SELECT x.codigo_orden,
           x.observaciones,
           x.estado_lote,
           x.tono,
           COALESCE(NULLIF(x.gramaje, '')::numeric(10, 3), 0),
           COALESCE(NULLIF(x.ancho, '')::numeric(10, 3), 0),
           COALESCE(NULLIF(x.encogimiento_ancho, '')::numeric(10, 3), 0),
           x.solidez_humedo,
           x.solidez_frote,
           COALESCE(NULLIF(x.kilos_prueba, '')::numeric(10, 3), 0),
           x.defectos_observados,
           p_usuario,
           COALESCE(NULLIF(x.encogimiento_largo, '')::numeric(10, 3), 0)
    FROM JSONB_TO_RECORD(p_datajs::jsonb) x (codigo_orden text, observaciones text, estado_lote text,
                                             tono text, gramaje text, ancho text, encogimiento_ancho text,
                                             encogimiento_largo text, kilos_prueba text, defectos_observados text,
                                             solidez_humedo text, solidez_frote text)
    ON CONFLICT ON CONSTRAINT unique_codigo_orden
        DO UPDATE SET observaciones       = EXCLUDED.observaciones,
                      estado_lote         = EXCLUDED.estado_lote,
                      tono                = EXCLUDED.tono,
                      gramaje             = EXCLUDED.gramaje,
                      ancho               = EXCLUDED.ancho,
                      encogimiento_ancho  = EXCLUDED.encogimiento_ancho,
                      solidez_humedo      = EXCLUDED.solidez_humedo,
                      solidez_frote       = EXCLUDED.solidez_frote,
                      kilos_prueba        = EXCLUDED.kilos_prueba,
                      defectos_observados = EXCLUDED.defectos_observados,
                      encogimiento_largo  = EXCLUDED.encogimiento_largo;
END;
$function$
;



dataCCRslt.field("tintoreria_pesos_balanza_id").IntegerValue

