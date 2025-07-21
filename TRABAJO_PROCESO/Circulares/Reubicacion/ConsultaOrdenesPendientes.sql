-- drop function trabajo_proceso.orden_rollo_consulta_pend_reub_crudos_resum()

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_consulta_pend_reub_crudos_resum()
    RETURNS TABLE
            (
                fecha_pesado_crudo date,
                codigo_orden       VARCHAR,
                rollos             bigint,
                item               VARCHAR,
                total_crudo        NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT MIN(od.fecha_pesado_crudo::date),
               od.codigo_orden,
               COUNT(od.numero_rollo) AS rollos,
               o.item,
               SUM(od.peso_crudo)     AS total_crudo
        FROM trabajo_proceso.ordenes_rollos_detalle od
                 JOIN trabajo_proceso.ordenes o ON o.codigo_orden = od.codigo_orden
        WHERE od.peso_crudo <> 0
          AND NOT od.reubicado_bodega_crudos
        GROUP BY od.codigo_orden, o.item;
END
$function$
;


select *
from trabajo_proceso.orden_rollo_consulta_pend_reub_crudos_resum()