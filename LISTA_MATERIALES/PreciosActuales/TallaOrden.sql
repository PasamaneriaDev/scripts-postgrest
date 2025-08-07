-- drop function control_inventarios.unidades_formato_reporte(p_unidad varchar, p_unid_desp int);

CREATE OR REPLACE FUNCTION control_inventarios.precios_actuales_talla_orden(v_item varchar)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN (COALESCE((CASE
                          WHEN (LEFT(v_item, 4) >= '1000' AND LEFT(v_item, 4) <= '1887') OR
                               (LEFT(v_item, 4) >= '1981' AND LEFT(v_item, 4) <= '1986') THEN
                              (CASE
                                   WHEN SUBSTR(v_item, 6, 2) = 'XS'
                                       THEN SUBSTR(v_item, 1, 5) || '55' || SUBSTR(v_item, 8, 8)
                                   WHEN SUBSTR(v_item, 6, 2) = '0S'
                                       THEN SUBSTR(v_item, 1, 5) || '60' || SUBSTR(v_item, 8, 8)
                                   WHEN SUBSTR(v_item, 6, 2) = '0M'
                                       THEN SUBSTR(v_item, 1, 5) || '65' || SUBSTR(v_item, 8, 8)
                                   WHEN SUBSTR(v_item, 6, 2) = '0L'
                                       THEN SUBSTR(v_item, 1, 5) || '70' || SUBSTR(v_item, 8, 8)
                                   WHEN SUBSTR(v_item, 6, 2) = 'XL'
                                       THEN SUBSTR(v_item, 1, 5) || '75' || SUBSTR(v_item, 8, 8)
                                   WHEN SUBSTR(v_item, 6, 2) = 'XX'
                                       THEN SUBSTR(v_item, 1, 5) || '80' || SUBSTR(v_item, 8, 8)
                                  END)
        END), v_item));
END;
$function$;