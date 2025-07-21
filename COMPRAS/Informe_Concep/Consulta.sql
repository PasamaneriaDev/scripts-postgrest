CREATE OR REPLACE FUNCTION control_inventarios.items_existencia_consep(p_periodo varchar)
    RETURNS table
            (
                item        varchar,
                descripcion varchar,
                bodega      varchar,
                ExisIni     numeric,
                Ingresos    numeric,
                Egresos     numeric,
                ExisFin     numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT i.item,
               i.descripcion,
               i.bodega,
               ihp.existencia                                            AS ExisIni,
               iha.cantidad_recibida_periodo                             AS Ingresos,
               iha.cantidad_usada_periodo + iha.cantidad_vendida_periodo AS Egresos,
               iha.existencia                                            AS ExisFin
        FROM control_inventarios.items i
                 LEFT JOIN control_inventarios.items_historico iha
                           ON i.item = iha.item AND iha.nivel = 'ILOC' AND iha.periodo = p_periodo
                 LEFT JOIN control_inventarios.items_historico ihp
                           ON i.item = ihp.item AND ihp.nivel = 'ILOC' AND
                              ihp.periodo = TO_CHAR(TO_DATE(p_periodo, 'YYYYMM') - INTERVAL '1 month', 'YYYYMM')
        WHERE alterno2 LIKE 'CONSEP%'
        ORDER BY i.item;
END;
$function$
;

SELECT *
FROM control_inventarios.items_existencia_consep('202409');