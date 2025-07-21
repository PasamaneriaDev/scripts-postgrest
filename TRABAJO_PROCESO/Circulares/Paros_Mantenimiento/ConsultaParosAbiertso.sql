-- drop function if exists trabajo_proceso.orden_rollo_buscar_x_codigo_orden_codigo_barra(character varying);

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_buscar_paro_mant_abiertos(p_tipo varchar)
    RETURNS TABLE
            (
                id_ordenes_rollos_paros_mantenimiento integer,
                codigo_orden                          character varying,
                numero_rollo                          character varying,
                maquina                               character varying,
                fecha_inicio                          timestamp WITHOUT TIME ZONE
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT pr.id_ordenes_rollos_paros_mantenimiento, pr.codigo_orden, pr.numero_rollo, pr.maquina, pr.fecha_inicio
        FROM trabajo_proceso.ordenes_rollos_paros_mantenimiento pr
        WHERE pr.fecha_fin IS NULL
          AND pr.tipo = p_tipo;
END
$function$
;
