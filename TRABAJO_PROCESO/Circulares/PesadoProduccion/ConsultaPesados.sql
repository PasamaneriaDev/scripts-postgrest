-- drop function if exists trabajo_proceso.orden_rollo_consulta_pesados_circulares(date);

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_consulta_pesados_circulares(p_fecha date)
    RETURNS TABLE
            (
                codigo_orden       character varying,
                item               character varying,
                numero_rollo       character varying,
                peso_crudo         numeric,
                usuario_pesa_crudo character varying,
                fecha_pesado_crudo timestamp WITHOUT TIME ZONE
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT od.codigo_orden, o.item, od.numero_rollo, od.peso_crudo, od.usuario_pesa_crudo, od.fecha_pesado_crudo
        FROM trabajo_proceso.ordenes_rollos_detalle od
                 JOIN trabajo_proceso.ordenes o ON o.codigo_orden = od.codigo_orden
        WHERE od.fecha_pesado_crudo::date = p_fecha;
END
$function$
;
