-- DROP FUNCTION auditoria.reporte_existencias_bodega_resumen_age(varchar, varchar, varchar, varchar, bool, bool, bool, bool, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_existencias_bodega_resumen_age(p_bodegas character varying,
                                                                            p_item_inicial character varying,
                                                                            p_item_final character varying,
                                                                            p_periodo character varying,
                                                                            p_negativos boolean, p_por_ubicac boolean,
                                                                            p_con_cero boolean, p_val_costo boolean,
                                                                            p_ubicacion character varying,
                                                                            p_existencia character varying,
                                                                            p_tipo character varying,
                                                                            p_articulo character varying)
    RETURNS TABLE
            (
                item1            character varying,
                codigo_rotacion1 character varying,
                cantidad1        numeric,
                item2            character varying,
                codigo_rotacion2 character varying,
                cantidad2        numeric,
                item3            character varying,
                codigo_rotacion3 character varying,
                cantidad3        numeric,
                item4            character varying,
                codigo_rotacion4 character varying,
                cantidad4        numeric,
                item5            character varying,
                codigo_rotacion5 character varying,
                cantidad5        numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    PERFORM auditoria.genera_existencia_bodega_temp(p_bodegas, p_item_inicial, p_item_final, p_periodo, p_negativos,
                                                    p_por_ubicac, p_con_cero, p_val_costo, p_ubicacion, p_existencia,
                                                    p_tipo, p_articulo);

    RETURN QUERY
        WITH data AS (SELECT item,
                             codigo_rotacion,
                             existencia,
                             ROW_NUMBER() OVER () AS rn,
                             COUNT(*) OVER ()     AS total_rows
                      FROM _temp_exist_bod),
             split_data AS (SELECT item,
                                   codigo_rotacion,
                                   existencia,
                                   rn,
                                   (rn - 1) % 5 + 1                                          AS grupo,
                                   ROW_NUMBER() OVER (PARTITION BY (rn - 1) % 5 ORDER BY rn) AS row_in_group
                            FROM data)
        SELECT d1.item            AS item1,
               d1.codigo_rotacion AS codigo_rotacion1,
               d1.existencia      AS cantidad1,
               d2.item            AS item2,
               d2.codigo_rotacion AS codigo_rotacion2,
               d2.existencia      AS cantidad2,
               d3.item            AS item3,
               d3.codigo_rotacion AS codigo_rotacion3,
               d3.existencia      AS cantidad3,
               d4.item            AS item4,
               d4.codigo_rotacion AS codigo_rotacion4,
               d4.existencia      AS cantidad4,
               d5.item            AS item5,
               d5.codigo_rotacion AS codigo_rotacion5,
               d5.existencia      AS cantidad5
        FROM (SELECT * FROM split_data WHERE grupo = 1) AS d1
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 2) AS d2
                           ON d1.row_in_group = d2.row_in_group
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 3) AS d3
                           ON d1.row_in_group = d3.row_in_group
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 4) AS d4
                           ON d1.row_in_group = d4.row_in_group
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 5) AS d5
                           ON d1.row_in_group = d5.row_in_group
        ORDER BY d1.row_in_group;

END;
$function$
;
