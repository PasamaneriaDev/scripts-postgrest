-- DROP FUNCTION puntos_venta.reporte_ventas_comparativa_semanal(p_fecha_inicio date, p_fecha_fin date, p_bodegas character varying[])

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_comparativa_semanal(p_fecha_inicio date, p_fecha_fin date, p_bodegas character varying[])
    RETURNS TABLE
            (
                semana_actual              text,
                semana_anterior            text,
                semana_anio_anterior       text,
                dia_semana                 text,
                bodega                     varchar,
                descripcion                varchar,
                fecha_act                  date,
                num_transacciones_act      integer,
                total_venta_act            numeric,
                fecha_ant                  date,
                num_transacciones_ant      integer,
                total_venta_ant            numeric,
                fecha_anio_ant             date,
                num_transacciones_anio_ant integer,
                total_venta_anio_ant       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    lv_ini_sem_ant  date;
    lv_fin_sem_ant  date;
    lv_ini_anio_ant date;
    lv_fin_anio_ant date;
BEGIN

    -- Calcular la fechas de la semana pasada
    SELECT (p_fecha_inicio - INTERVAL '7 days')::date AS fecha_menos_7_dias,
           (p_fecha_fin - INTERVAL '7 days')::date    AS fecha_menos_7_dia
    INTO lv_ini_sem_ant, lv_fin_sem_ant;

    -- Calcular la fechas del año anterior
    SELECT (p_fecha_inicio - INTERVAL '52 WEEKS')::date AS fecha_anio_anterior,
           (p_fecha_fin - INTERVAL '52 WEEKS')::date    AS fecha_anio_anterior
    INTO lv_ini_anio_ant, lv_fin_anio_ant;

    -- Tabla con Bodegas - Dias
    DROP TABLE IF EXISTS temp_bodegas_dias;
    IF ARRAY_LENGTH(p_bodegas, 1) IS NULL THEN
        CREATE TEMP TABLE temp_bodegas_dias AS
        SELECT ib.bodega, dia.dia_semana, dia.dia
        FROM control_inventarios.id_bodegas ib
                 CROSS JOIN (SELECT TO_CHAR(day::date, 'TMDay') AS dia_semana, day AS dia
                             FROM GENERATE_SERIES('2024-11-25'::date, '2024-12-01'::date,
                                                  '1 day'::interval) AS day) AS dia
        WHERE ib.es_punto_venta
          AND ib.fecha_fin_transacciones IS NULL
        ORDER BY ib.bodega, dia.dia;
    ELSE
        CREATE TEMP TABLE temp_bodegas_dias AS
        SELECT bodegas.bodega, dia.dia_semana, dia.dia
        FROM (SELECT UNNEST(p_bodegas) bodega) AS bodegas
                 CROSS JOIN (SELECT TO_CHAR(day::date, 'TMDay') AS dia_semana, day AS dia
                             FROM GENERATE_SERIES('2024-11-25'::date, '2024-12-01'::date,
                                                  '1 day'::interval) AS day) AS dia
        ORDER BY bodegas.bodega, dia.dia;
    END IF;

    RETURN QUERY
        SELECT p_fecha_inicio || ' - ' || p_fecha_fin      AS semana_actual,
               lv_ini_sem_ant || ' - ' || lv_fin_sem_ant   AS semana_anterior,
               lv_ini_anio_ant || ' - ' || lv_fin_anio_ant AS semana_anio_anterior,
               ds.dia_semana,
               ds.bodega,
               ib.descripcion,
               sem_act.fecha                               AS fecha_act,
               sem_act.num_transacciones                   AS num_transacciones_act,
               sem_act.total_venta                         AS total_venta_act,
               sem_ant.fecha                               AS fecha_ant,
               sem_ant.num_transacciones                   AS num_transacciones_ant,
               sem_ant.total_venta                         AS total_venta_ant,
               anio_ant.fecha                              AS fecha_anio_ant,
               anio_ant.num_transacciones                  AS num_transacciones_anio_ant,
               anio_ant.total_venta                        AS total_venta_anio_ant
        FROM temp_bodegas_dias AS ds
                 JOIN control_inventarios.id_bodegas ib ON ib.bodega = ds.bodega
                 LEFT JOIN (SELECT fd.bodega,
                                   fd.fecha,
                                   TO_CHAR(fd.fecha, 'TMDay')             AS                dia_semana,
                                   COUNT(DISTINCT fd.referencia)::INTEGER AS                num_transacciones,
                                   SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                                             COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
                            FROM puntos_venta.facturas_detalle fd
                                     JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                            WHERE (FC.FECHA BETWEEN p_fecha_inicio AND p_fecha_fin)
                            GROUP BY fd.bodega, fd.fecha
                            ORDER BY fd.bodega, fd.fecha)
            AS sem_act ON sem_act.
                              dia_semana = ds.dia_semana AND sem_act.bodega = ds.bodega
                 LEFT JOIN (SELECT fd.bodega,
                                   fd.fecha,
                                   TO_CHAR(fd.fecha, 'TMDay')             AS                dia_semana,
                                   COUNT(DISTINCT fd.referencia)::INTEGER AS                num_transacciones,
                                   SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                                             COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
                            FROM puntos_venta.facturas_detalle fd
                                     JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                            WHERE (FC.FECHA BETWEEN lv_ini_sem_ant AND lv_fin_sem_ant)
                            GROUP BY fd.bodega, fd.fecha
                            ORDER BY fd.bodega, fd.fecha)
            AS sem_ant ON sem_ant.
                              dia_semana = ds.dia_semana AND sem_ant.bodega = ds.bodega
                 LEFT JOIN (SELECT fd.bodega,
                                   fd.fecha,
                                   TO_CHAR(fd.fecha, 'TMDay')             AS                dia_semana,
                                   COUNT(DISTINCT fd.referencia)::INTEGER AS                num_transacciones,
                                   SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                                             COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
                            FROM puntos_venta.facturas_detalle fd
                                     JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                            WHERE (FC.FECHA BETWEEN lv_ini_anio_ant AND lv_fin_anio_ant)
                            GROUP BY fd.bodega, fd.fecha
                            ORDER BY fd.bodega, fd.fecha)
            AS anio_ant ON anio_ant.
                               dia_semana = ds.dia_semana AND anio_ant.bodega = ds.bodega
        WHERE -- (sem_act.fecha IS NOT NULL OR sem_ant.fecha IS NOT NULL OR anio_ant.fecha IS NOT NULL) OR
           (COALESCE(sem_act.total_venta, 0) <> 0 OR COALESCE(sem_ant.total_venta, 0) <> 0 OR
               COALESCE(anio_ant.total_venta, 0) <> 0)
        ORDER BY ds.bodega, ds.dia;
END;
$function$
;