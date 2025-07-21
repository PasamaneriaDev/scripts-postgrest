/*
 drop function auditoria.reporte_etiquetas_ubicaciones_doble(character varying);
 */

CREATE OR REPLACE FUNCTION auditoria.reporte_etiquetas_ubicaciones_doble(p_datajs character varying)
    RETURNS TABLE
            (
                bodega1    text,
                ubicacion1 text,
                bodega2    text,
                ubicacion2 text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_col integer = 2;
BEGIN

    RETURN QUERY
        WITH data AS (SELECT a.bodega,
                             a.ubicacion,
                             ROW_NUMBER() OVER () AS rn,
                             COUNT(*) OVER ()     AS total_rows
                      FROM JSON_TO_RECORDSET(p_datajs::json) a (bodega text, ubicacion text)),
             split_data AS (SELECT bodega,
                                   ubicacion,
                                   rn,
                                   (rn - 1) % v_col + 1                                          AS grupo,
                                   ROW_NUMBER() OVER (PARTITION BY (rn - 1) % v_col ORDER BY rn) AS row_in_group
                            FROM data)
        SELECT d1.bodega    AS bodega1,
               d1.ubicacion AS ubicacion1,
               d2.bodega    AS bodega2,
               d2.ubicacion AS ubicacion2
        FROM (SELECT * FROM split_data WHERE grupo = 1) AS d1
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 2) AS d2
                           ON d1.row_in_group = d2.row_in_group
        ORDER BY d1.row_in_group;

END;
$function$
;


