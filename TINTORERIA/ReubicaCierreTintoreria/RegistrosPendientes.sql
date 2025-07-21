-- drop FUNCTION trabajo_proceso.tintoreria_ordenes_x_recibir_bodega(p_tintoreria_ordenes_enviadas_id integer, p_bodega varchar, p_ubicacion varchar)

CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_ordenes_x_recibir_bodega(p_tintoreria_ordenes_enviadas_id integer,
                                                                               p_bodega varchar, p_ubicacion varchar)
    RETURNS TABLE
            (
                fecha                          timestamp,
                codigo_orden                   varchar,
                item                           varchar,
                descripcion                    varchar,
                unidad_medida                  varchar,
                bodega                         varchar,
                ubicacion                      varchar,
                cantidad_planificada           numeric,
                cantidad_fabricada             numeric,
                cantidad_recibida              numeric,
                cantidad_reubica               numeric,
                rollos                         numeric,
                cerrado                        boolean,
                reubicado                      boolean,
                tintoreria_ordenes_enviadas_id integer
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT t.creacion_fecha,
               o.codigo_orden,
               o.item,
               i.descripcion,
               i.unidad_medida,
               t.bodega,
               t.ubicacion,
               o.cantidad_planificada,
               o.cantidad_fabricada,
               t.cantidad,
               t.cantidad_reubica,
               t.rollos,
               (o.estado = 'Cerrada')            AS cerrado,
               (t.cantidad = t.cantidad_reubica) AS reubicado,
               t.tintoreria_ordenes_enviadas_id
        FROM trabajo_proceso.tintoreria_control_calidad tcc
                 JOIN trabajo_proceso.ordenes o ON tcc.codigo_orden = o.codigo_orden
                 JOIN trabajo_proceso.tintoreria_ordenes_enviadas t ON t.codigo_orden = o.codigo_orden
                 JOIN control_inventarios.items i ON i.item = o.item
        WHERE (t.bodega = p_bodega
            AND t.ubicacion = p_ubicacion)
          AND (o.estado = 'Abierta' OR
               t.cantidad <> t.cantidad_reubica)
          AND (p_tintoreria_ordenes_enviadas_id = 0 OR
               t.tintoreria_ordenes_enviadas_id = p_tintoreria_ordenes_enviadas_id)
        ORDER BY t.creacion_fecha desc, t.codigo_orden;
END;
$function$
;
