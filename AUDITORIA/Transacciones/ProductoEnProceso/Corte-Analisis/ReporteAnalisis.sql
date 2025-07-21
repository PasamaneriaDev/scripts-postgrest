-- DROP FUNCTION control_inventarios.inventarios_proceso_reporte_analisis(p_bodega character varying, solo_diferencias boolean)

CREATE OR REPLACE FUNCTION control_inventarios.inventarios_proceso_reporte_analisis(p_bodega character varying, solo_diferencias boolean)
    RETURNS TABLE
            (
                bodega         character varying,
                ubicacion      varchar,
                item           varchar,
                stkumid        character varying,
                descripcion    character varying,
                documento      text,
                sistema        numeric,
                toma           numeric,
                costo_promedio numeric,
                diferencia     numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_condicion_segunda text;
    v_sql               text;
BEGIN
    SELECT condicion_segunda
    INTO v_condicion_segunda
    FROM control_inventarios.inventarios_proceso_condicion_bodega(p_bodega);

    v_sql = FORMAT(
            'WITH z
                 AS
                 (SELECT t1.bodega
                       , t1.ubicacion
                       , t1.item
                       , t2.unidad_medida
                       , t2.descripcion
                       , ajuste_suma.documentos AS documento
                       , t1.existencia                           AS sistema
                       , COALESCE(ajuste_suma.total_ajuste, .0) AS toma
                       , t2.costo_promedio
                  FROM control_inventarios.ubicaciones_corte_inventario t1
                           INNER JOIN control_inventarios.items t2
                                      ON t1.item = t2.item
                           LEFT JOIN LATERAL (
                                    SELECT SUM(aj.cantidad_ajuste) AS total_ajuste,
                                           STRING_AGG(aj.documento, '', '') as documentos
                                    FROM control_inventarios.ajustes aj
                                    WHERE aj.tipo = ''T''
                                      AND aj.status <> ''V''
                                      AND aj.cantidad_ajuste <> 0
                                      AND aj.ubicacion = t1.ubicacion
                                      AND aj.item = t1.item
                                      AND LEFT(aj.ubicacion, 1) = LEFT(%1$L, 1)
                                      AND %2$s
                                ) ajuste_suma ON true
                  WHERE t1.bodega_proceso = %1$L
                  UNION
                  SELECT aj.bodega,
                         aj.ubicacion,
                         aj.item,
                         i.unidad_medida,
                         i.descripcion,
                         STRING_AGG(aj.documento, '', '') as documento,
                         .0::NUMERIC AS existencia,
                         SUM(aj.cantidad_ajuste)::NUMERIC as toma,,
                         i.costo_promedio
                  FROM control_inventarios.ajustes aj
                           INNER JOIN
                       control_inventarios.items i
                       ON aj.item = i.item
                  WHERE aj.tipo = ''T''
                    AND aj.status <> ''V''
                    AND aj.cantidad_ajuste <> 0
                    AND LEFT(aj.ubicacion, 1) = LEFT(%1$L, 1)
                    AND %2$s
                    AND NOT EXISTS (SELECT 1
                                    FROM control_inventarios.ubicaciones_corte_inventario u
                                    WHERE u.item = aj.item
                                      AND u.ubicacion = aj.ubicacion
                                      AND u.bodega_proceso = %1$L)
                  GROUP BY aj.bodega, aj.ubicacion, aj.item, i.item)
                SELECT *, z.toma - z.sistema AS diferencia
                FROM z
                WHERE CASE WHEN %3$s THEN z.toma - z.sistema <> 0 ELSE (z.toma <> 0 OR z.sistema <> 0) END
                ORDER BY item, ubicacion;',
            p_bodega, v_condicion_segunda, solo_diferencias::text);

    RETURN QUERY
        EXECUTE v_sql;

END;
$function$
;
