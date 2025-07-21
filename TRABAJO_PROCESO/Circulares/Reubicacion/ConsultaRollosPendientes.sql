-- drop function trabajo_proceso.orden_rollo_consulta_pend_reub_crudos(p_codigo_orden VARCHAR)

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_consulta_pend_reub_crudos(p_codigo_orden VARCHAR)
    RETURNS TABLE
            (
                fecha_pesado_crudo TIMESTAMP,
                codigo_orden       VARCHAR,
                numero_rollo       VARCHAR,
                item               VARCHAR,
                peso_crudo         NUMERIC,
                tonalidad          VARCHAR
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT od.fecha_pesado_crudo, o.codigo_orden, od.numero_rollo, o.item, od.peso_crudo, od.tonalidad
        FROM trabajo_proceso.ordenes_rollos_detalle od
                 JOIN trabajo_proceso.ordenes o ON o.codigo_orden = od.codigo_orden
        WHERE od.peso_crudo <> 0
          AND NOT od.reubicado_bodega_crudos
          AND (od.codigo_orden = p_codigo_orden OR p_codigo_orden = '')
        ORDER BY od.codigo_orden, od.numero_rollo;

END
$function$
;


SELECT *
FROM trabajo_proceso.orden_rollo_consulta_pend_reub_crudos('7M-02000088') a



SELECT   fecha_pesado_crudo::date as fecha_pesado_crudo, codigo_orden, numero_rollo,   peso_crudo, tonalidad FROM trabajo_proceso.orden_rollo_consulta_pend_reub_crudos('7M-02000088')