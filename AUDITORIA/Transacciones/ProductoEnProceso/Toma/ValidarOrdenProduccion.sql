-- drop function  auditoria.papeleta_validar_orden_produccion(p_orden varchar, p_documento varchar, p_ordenes_validas varchar)

CREATE OR REPLACE FUNCTION auditoria.papeleta_validar_orden_produccion(p_orden varchar, p_documento varchar, p_ordenes_validas varchar)
    RETURNS TABLE
            (
                orden                VARCHAR,
                item                 VARCHAR,
                cantidad_planificada NUMERIC,
                secuencia_ajus       integer,
                cantidad_ajuste      NUMERIC,
                costo                NUMERIC,
                costo_nuevo          NUMERIC,
                cantidad             NUMERIC,
                unidad_medida        VARCHAR,
                descripcion          VARCHAR,
                numero_decimales     numeric,
                total_costo          NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_usa_codigo boolean;
    v_orden      varchar;
BEGIN
    v_usa_codigo = POSITION('-' IN p_orden) > 0;

    v_orden := CASE
                   WHEN v_usa_codigo THEN p_orden
                   ELSE LPAD(TRIM(p_orden), 8, '0')
        END;

    RETURN QUERY
        SELECT v_orden::varchar AS orden,
               o.item,
               o.cantidad_planificada,
               a.secuencia      AS secuencia_ajus,
               a.cantidad_ajuste, -- Sqty
               a.costo,
               a.costo_nuevo,
               a.cantidad,
               ic.unidad_medida,
               ic.descripcion,
               ic.numero_decimales,
               ic.total_costo   AS total_costo
        FROM trabajo_proceso.ordenes o
                 LEFT JOIN control_inventarios.ajustes a
                           ON a.orden = o.codigo_orden
                               AND a.documento = LPAD(p_documento, 10, '0')
                               AND a.tipo = 'T'
                               AND a.status = ''
                 LEFT JOIN auditoria.item_costo_standard_total(o.item) ic
                           ON o.item = ic.item
        WHERE o.estado = 'Abierta'
          AND LEFT(o.codigo_orden, 3) = ANY (('{' || p_ordenes_validas || '}')::TEXT[])
          AND (CASE
                   WHEN v_usa_codigo THEN o.codigo_orden
                   ELSE o.secuencia_codigo_barra
            END) = v_orden;
END;
$function$
;






