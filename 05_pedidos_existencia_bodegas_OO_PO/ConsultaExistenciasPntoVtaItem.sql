-- drop function control_inventarios.obtiene_existencias_item_puntos_venta_mt_yd_pz(varchar);

CREATE OR REPLACE FUNCTION control_inventarios.obtiene_existencias_item_puntos_venta_mt_yd_pz(p_item VARCHAR)
    RETURNS TABLE
            (
                bodega VARCHAR,
                descripcion varchar,
                eximt  NUMERIC,
                exipz  NUMERIC,
                exiyd  NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    -- Retorna las existencias de un item en las bodegas que son puntos de venta en
    -- las Unidades de Medida MT, PZ y YD.
    RETURN QUERY
        WITH cte AS
                 (SELECT b.bodega,
                         b.descripcion,
                         round(control_inventarios.obtiene_existencia_item_bodega(b.bodega,
                                                                            LEFT(p_item, -1) || 4), 2) AS eximt,
                         round(control_inventarios.obtiene_existencia_item_bodega(b.bodega,
                                                                            LEFT(p_item, -1) || 5), 2) AS exiyd,
                         round(control_inventarios.obtiene_existencia_item_bodega(b.bodega,
                                                                            LEFT(p_item, -1) || 0), 2) AS exipz
                  FROM control_inventarios.id_bodegas b
                  WHERE es_punto_venta)
        SELECT t.bodega, t.descripcion, t.eximt, t.exipz, t.exiyd
        FROM cte AS t
        WHERE NOT (t.eximt = 0 AND t.exiyd = 0 AND t.exipz = 0);
END
$function$
;


