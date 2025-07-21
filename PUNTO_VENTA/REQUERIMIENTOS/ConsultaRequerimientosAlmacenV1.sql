-- DROP FUNCTION puntos_venta.requerimientos_consulta(varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_consulta(p_centro_costo_origen character varying,
                                                                p_fecha_inicial character varying,
                                                                p_fecha_final character varying,
                                                                p_estado character varying,
                                                                p_nro_requerimiento character varying)
    RETURNS TABLE
            (
                nro_requerimiento      character varying,
                item                   character varying,
                descripcion            character varying,
                fecha_solicitud        date,
                fecha_requerimiento    date,
                cantidad_solicitada    character varying,
                comentario             character varying,
                cantidad_entragada     numeric,
                fecha_entregada        date,
                fecha_recibido_almacen date,
                estado                 text,
                centro_costo           character varying,
                nombre_centro_costo    character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT rg.nro_requerimiento,
               rg.item,
               it.descripcion,
               rg.fecha_solicitud,
               rg.fecha_requerimiento,
               rg.cantidad_solicitada,
               rg.comentario,
               rg.cantidad_entragada,
               rg.fecha_entregada,
               rg.fecha_recibido_almacen,
               CASE
                   WHEN rg.fecha_solicitud IS NOT NULL AND
                        rg.fecha_entregada IS NULL AND
                        rg.fecha_recibido_almacen IS NULL
                       THEN 'EN TRAMITE'
                   WHEN rg.fecha_entregada IS NOT NULL AND rg.fecha_recibido_almacen IS NULL
                       THEN 'ENVIADO'
                   WHEN rg.fecha_recibido_almacen IS NOT NULL
                       THEN 'RECIBIDO'
                   ELSE ''
                   END      AS estado,
               cc.codigo    AS centro_costo,
               cc.subcentro AS nombre_centro_costo
        FROM trabajo_proceso.requerimiento_guia rg
                 JOIN control_inventarios.items it ON it.item = rg.item
                 JOIN activos_fijos.centros_costos cc ON rg.centro_costo_origen = cc.codigo
        WHERE (rg.centro_costo_origen = p_centro_costo_origen OR p_centro_costo_origen = '')
          AND (rg.nro_requerimiento = p_nro_requerimiento OR p_nro_requerimiento = '')
          AND (p_fecha_inicial = '' OR p_fecha_final = '' OR
               rg.fecha_solicitud BETWEEN p_fecha_inicial::date AND p_fecha_final::date)
          AND ((p_estado = 'EN TRAMITE' AND rg.fecha_solicitud IS NOT NULL AND rg.fecha_entregada IS NULL AND
                rg.fecha_recibido_almacen IS NULL) OR
               (p_estado = 'ENVIADO' AND rg.fecha_entregada IS NOT NULL AND rg.fecha_recibido_almacen IS NULL) OR
               (p_estado = 'RECIBIDO' AND rg.fecha_recibido_almacen IS NOT NULL) OR
               (p_estado = '' AND TRUE))
          AND rg.centro_costo_origen IN (SELECT DISTINCT pa.centro_costo
                                         FROM SISTEMA.parametros_almacenes AS pa)
          AND rg.fecha_solicitud > '2024-11-15'
        ORDER BY rg.fecha_solicitud DESC;
END;
$function$
;
