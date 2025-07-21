CREATE OR REPLACE FUNCTION control_inventarios.obtiene_existencia_item_bodega(p_bodega varchar, p_item varchar)
    RETURNS TABLE
            (
                existencia numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT COALESCE(b.existencia, 0) AS existencia
        FROM control_inventarios.bodegas b
        WHERE b.bodega = p_bodega
          AND b.item = p_item;
    IF NOT FOUND THEN
        RETURN QUERY SELECT 0.0;
    END IF;
END
$function$
;



