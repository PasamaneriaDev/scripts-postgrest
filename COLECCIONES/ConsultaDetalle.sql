-- DROP FUNCTION colecciones.lotes_detalle_x_lista_coleccion_id(varchar);

CREATE OR REPLACE FUNCTION colecciones.lotes_detalle_x_lista_coleccion_id(p_colecciones_id character varying)
    RETURNS TABLE
            (
                coleccion_id     character varying,
                item             character varying,
                descripcion      character varying,
                codigo_rotacion  character varying,
                lote_inicial     numeric,
                lote_saldo       numeric,
                lote_recibido    numeric,
                lote_distribuido numeric,
                estado           character varying,
                creacion_fecha   date,
                creacion_hora    time,
                creacion_usuario character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    RETURN QUERY
        SELECT ld.coleccion_id,
               ld.item,
               i.descripcion,
               ld.codigo_rotacion,
               ld.lote_inicial,
               ld.lote_saldo,
               ld.lote_recibido,
               ld.lote_distribuido,
               ld.estado,
               ld.creacion_fecha::date AS creacion_fecha,
               ld.creacion_fecha::time AS creacion_hora,
               ld.creacion_usuario
        FROM colecciones.lotes_detalle ld
                 JOIN control_inventarios.items i ON ld.item = i.item
        WHERE ld.coleccion_id = ANY (STRING_TO_ARRAY(p_colecciones_id, ','))
        ORDER BY ld.coleccion_id, ld.item;

END;
$function$
;
