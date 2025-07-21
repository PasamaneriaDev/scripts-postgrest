-- drop function control_inventarios.obtiene_existencia_item_punto_venta(varchar);

CREATE OR REPLACE FUNCTION control_inventarios.obtiene_total_existencia_item_punto_venta(p_item varchar)
    RETURNS TABLE
            (
                existencia numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT COALESCE(SUM(COALESCE(b.existencia, 0)), 0) AS existencia
        FROM control_inventarios.bodegas b
                 JOIN control_inventarios.id_bodegas ib
                      ON b.bodega = ib.bodega
        WHERE b.item = p_item
          AND ib.es_punto_venta;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0.0;
    END IF;
END
$function$
;