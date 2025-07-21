-- DROP FUNCTION trabajo_proceso.reporte_unidades_equivalentes_txt(text);

CREATE OR REPLACE FUNCTION trabajo_proceso.reporte_unidades_equivalentes_txt(p_datajs text)
    RETURNS TABLE
            (
                item          character varying,
                descripcion   character varying,
                unidad_medida character varying,
                cantidad      numeric,
                num_uni       numeric,
                tiempo        numeric,
                total_tiempo  numeric,
                puntaje       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_uni_equivalente NUMERIC(10, 2);
BEGIN

    SELECT p.numero
    INTO v_uni_equivalente
    FROM sistema.parametros p
    WHERE p.CODIGO = 'UNIDAD_EQUIVALE'
      AND p.modulo_id = 'TRABPROC';

    RETURN QUERY
        WITH cte AS (SELECT i.item,
                            i.descripcion,
                            a.cantidad,
                            i.ruta,
                            i.unidad_medida
                     FROM JSON_TO_RECORDSET(p_datajs::json) a (item text, cantidad numeric)
                              JOIN control_inventarios.items i ON i.item = a.item),
             ruta_tiempo AS (SELECT r.ruta,
                                    SUM(CASE
                                            WHEN c.departamento = '11' AND RIGHT(TRIM(r.operacion), 1) <> '1'
                                                THEN CASE
                                                         WHEN r.unidades = 'UNO' THEN r.minutos
                                                         WHEN r.unidades = 'CIEN' THEN r.minutos / 100
                                                         WHEN r.unidades = 'MIL' THEN r.minutos / 1000
                                                END
                                            ELSE 0
                                        END) AS tiempo
                             FROM rutas.rutas r
                                      JOIN rutas.centros c ON c.codigo = r.centro
                                      JOIN (SELECT DISTINCT ruta FROM cte) AS distinct_cte ON distinct_cte.ruta = r.ruta
                             GROUP BY r.ruta)
        SELECT cte.item,
               REPLACE(REPLACE(cte.descripcion, ',', ''), ';', '')::varchar          AS descripcion,
               cte.unidad_medida,
               cte.cantidad                                                          AS cantidad,
               CASE
                   WHEN SUBSTRING(cte.item FROM 14 FOR 1) = 'A' THEN cte.cantidad * 10
                   ELSE cte.cantidad * CAST(SUBSTRING(cte.item FROM 14 FOR 1) AS NUMERIC)
                   END                                                               AS num_uni,
               rt.tiempo,
               (cte.cantidad * rt.tiempo)                                            AS total_tiempo,
               COALESCE(ROUND((cte.cantidad * rt.tiempo) / v_uni_equivalente, 2), 0) AS puntaje
        FROM cte
                 LEFT JOIN ruta_tiempo AS rt ON rt.ruta = cte.ruta
        ORDER BY cte.item;
END;
$function$
;
