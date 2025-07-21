-- DROP FUNCTION control_inventarios.item_consulta_detalle_colecciones(varchar);

CREATE OR REPLACE FUNCTION control_inventarios.item_consulta_detalle_colecciones(p_item character varying)
    RETURNS TABLE
            (
                coleccion_id     character varying,
                codigo_rotacion  character varying,
                lote_inicial     numeric,
                lote_saldo       numeric,
                lote_recibido    numeric,
                lote_distribuido numeric,
                creacion_fecha   date,
                creacion_usuario character varying,
                estado           character varying,
                fecha_salio_008  date
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN

    RETURN QUERY
        SELECT ld.coleccion_id,
               ld.codigo_rotacion,
               ld.lote_inicial,
               ld.lote_saldo,
               ld.lote_recibido,
               ld.lote_distribuido,
               ld.creacion_fecha::date,
               ld.creacion_usuario,
               ld.estado,
               ld.fecha_salio_008
        FROM colecciones.lotes_detalle ld
        WHERE ld.item = p_item
              --AND COALESCE(ld.estado, '') = ''
        ORDER BY ld.creacion_fecha;
END;
$function$
;
