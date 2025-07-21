-- DROP FUNCTION control_inventarios.inventarios_reporte_analisis(p_bodega character varying, solo_diferencias boolean)

CREATE OR REPLACE FUNCTION control_inventarios.inventarios_reporte_analisis(p_bodega character varying, solo_diferencias boolean)
    RETURNS TABLE
            (
                bodega         character varying,
                ubicacion      character varying,
                item           text,
                stkumid        character varying,
                tipo_orden     character varying,
                descripcion    character varying,
                sistema        numeric,
                toma           numeric,
                costo_promedio numeric,
                diferencia     numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        WITH z
                 AS
                 (SELECT t1.bodega,
                         t1.ubicacion,
                         t1.item::Text,
                         t2.unidad_medida,
                         t2.tipo_orden,
                         t2.descripcion,
                         t1.existencia    AS sistema,
                         CASE
                             WHEN t1.ubicacion = '0000'
                                 THEN COALESCE((SELECT SUM(t3.cantidad)
                                                FROM control_inventarios.inventario_almacences t3
                                                WHERE t3.bodega = t1.bodega
                                                  AND t3.cod_item = t1.item), .0)
                             ELSE .0
                             END::numeric AS toma,
                         t2.costo_promedio
                  FROM control_inventarios.ubicaciones_corte_inventario t1
                           INNER JOIN control_inventarios.items t2
                                      ON t1.item = t2.item
                  WHERE t1.bodega = p_bodega
                  UNION
                  SELECT ia.bodega,
                         '0000'::TEXT,
                         ia.cod_item::TEXT,
                         i.unidad_medida,
                         i.tipo_orden,
                         ia.descripcion,
                         .0::NUMERIC AS existencia,
                         SUM(ia.cantidad)::NUMERIC,
                         i.costo_promedio
                  FROM control_inventarios.inventario_almacences ia
                           INNER JOIN
                       control_inventarios.items i
                       ON ia.cod_item = i.item
                  WHERE ia.bodega = p_bodega
                    AND NOT EXISTS (SELECT 1
                                    FROM control_inventarios.ubicaciones_corte_inventario u
                                    WHERE u.item = ia.cod_item
                                      AND u.bodega = ia.bodega)
                  GROUP BY ia.bodega, ia.cod_item, ia.descripcion, i.item)
        SELECT *, z.toma - z.sistema AS diferencia
        FROM z
        WHERE CASE WHEN solo_diferencias THEN z.toma - z.sistema <> 0 ELSE (z.toma <> 0 OR z.sistema <> 0) END
        ORDER BY item, ubicacion;
END;
$function$
;
