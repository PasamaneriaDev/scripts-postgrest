-- DROP function auditoria.reporte_existencias_bodega_resumen_age(p_bodegas varchar, p_item_inicial varchar, p_item_final varchar, p_periodo varchar, p_negativos boolean, p_por_ubicac boolean, p_con_cero boolean, p_val_costo boolean, p_ubicacion varchar, p_existencia varchar, p_tipo varchar, p_articulo varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_existencias_bodega_resumen_bod(p_bodegas varchar,
                                                                            p_item_inicial varchar,
                                                                            p_item_final varchar,
                                                                            p_periodo varchar,
                                                                            p_negativos boolean,
                                                                            p_por_ubicac boolean,
                                                                            p_con_cero boolean,
                                                                            p_val_costo boolean,
                                                                            p_ubicacion varchar,
                                                                            p_existencia varchar,
                                                                            p_tipo varchar,
                                                                            p_articulo varchar)
    RETURNS TABLE
            (
                item1            varchar,
                codigo_rotacion1 varchar,
                cantidad1        numeric,
                valor1           numeric,
                transito1        numeric,
                ubicacion1       varchar,
                item2            varchar,
                codigo_rotacion2 varchar,
                cantidad2        numeric,
                valor2           numeric,
                transito2        numeric,
                ubicacion2       varchar,
                item3            varchar,
                codigo_rotacion3 varchar,
                cantidad3        numeric,
                valor3           numeric,
                transito3        numeric,
                ubicacion3       varchar
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
                             valor,
                             transito,
                             ubicacion,
                             ROW_NUMBER() OVER () AS rn,
                             COUNT(*) OVER ()     AS total_rows
                      FROM _temp_exist_bod),
             split_data AS (SELECT item,
                                   codigo_rotacion,
                                   existencia,
                                   valor,
                                   transito,
                                   ubicacion,
                                   rn,
                                   (rn - 1) % 3 + 1                                          AS grupo,
                                   ROW_NUMBER() OVER (PARTITION BY (rn - 1) % 3 ORDER BY rn) AS row_in_group
                            FROM data)
        SELECT d1.item            AS item1,
               d1.codigo_rotacion AS codigo_rotacion1,
               d1.existencia      AS cantidad1,
               d1.valor           AS valor1,
               d1.transito        AS transito1,
               d1.ubicacion       AS ubicacion1,
               d2.item            AS item2,
               d2.codigo_rotacion AS codigo_rotacion2,
               d2.existencia      AS cantidad2,
               d2.valor           AS valor2,
               d2.transito        AS transito2,
               d2.ubicacion       AS ubicacion2,
               d3.item            AS item3,
               d3.codigo_rotacion AS codigo_rotacion3,
               d3.existencia      AS cantidad3,
               d3.valor           AS valor3,
               d3.transito        AS transito3,
               d3.ubicacion       AS ubicacion3
        FROM (SELECT * FROM split_data WHERE grupo = 1) AS d1
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 2) AS d2
                           ON d1.row_in_group = d2.row_in_group
                 LEFT JOIN (SELECT * FROM split_data WHERE grupo = 3) AS d3
                           ON d1.row_in_group = d3.row_in_group
        ORDER BY d1.row_in_group;

END;
$function$
;


