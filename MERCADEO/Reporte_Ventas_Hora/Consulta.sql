CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_x_hora(p_bodega varchar, p_fecha_inicial date, p_fecha_final date)
    RETURNS table
            (
                fecha           DATE,
                terminal        VARCHAR,
                total_08        NUMERIC,
                num_facturas_08 INTEGER,
                total_09        NUMERIC,
                num_facturas_09 INTEGER,
                total_10        NUMERIC,
                num_facturas_10 INTEGER,
                total_11        NUMERIC,
                num_facturas_11 INTEGER,
                total_12        NUMERIC,
                num_facturas_12 INTEGER,
                total_13        NUMERIC,
                num_facturas_13 INTEGER,
                total_14        NUMERIC,
                num_facturas_14 INTEGER,
                total_15        NUMERIC,
                num_facturas_15 INTEGER,
                total_16        NUMERIC,
                num_facturas_16 INTEGER,
                total_17        NUMERIC,
                num_facturas_17 INTEGER,
                total_18        NUMERIC,
                num_facturas_18 INTEGER,
                total_19        NUMERIC,
                num_facturas_19 INTEGER,
                total_20        NUMERIC,
                num_facturas_20 INTEGER,
                total_21        NUMERIC,
                num_facturas_21 INTEGER,
                total_22        NUMERIC,
                num_facturas_22 INTEGER,
                total_23        NUMERIC,
                num_facturas_23 INTEGER,
                total           NUMERIC,
                num_facturas    INTEGER
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        SELECT fc.fecha,
               fc.terminal,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '08' THEN fc.monto_total - fc.iva END) AS total_08,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '08' THEN 1 END)::integer              AS num_facturas_08,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '09' THEN fc.monto_total - fc.iva END) AS total_09,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '09' THEN 1 END)::integer              AS num_facturas_09,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '10' THEN fc.monto_total - fc.iva END) AS total_10,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '10' THEN 1 END)::integer              AS num_facturas_10,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '11' THEN fc.monto_total - fc.iva END) AS total_11,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '11' THEN 1 END)::integer              AS num_facturas_11,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '12' THEN fc.monto_total - fc.iva END) AS total_12,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '12' THEN 1 END)::integer              AS num_facturas_12,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '13' THEN fc.monto_total - fc.iva END) AS total_13,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '13' THEN 1 END)::integer              AS num_facturas_13,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '14' THEN fc.monto_total - fc.iva END) AS total_14,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '14' THEN 1 END)::integer              AS num_facturas_14,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '15' THEN fc.monto_total - fc.iva END) AS total_15,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '15' THEN 1 END)::integer              AS num_facturas_15,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '16' THEN fc.monto_total - fc.iva END) AS total_16,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '16' THEN 1 END)::integer              AS num_facturas_16,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '17' THEN fc.monto_total - fc.iva END) AS total_17,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '17' THEN 1 END)::integer              AS num_facturas_17,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '18' THEN fc.monto_total - fc.iva END) AS total_18,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '18' THEN 1 END)::integer              AS num_facturas_18,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '19' THEN fc.monto_total - fc.iva END) AS total_19,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '19' THEN 1 END)::integer              AS num_facturas_19,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '20' THEN fc.monto_total - fc.iva END) AS total_20,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '20' THEN 1 END)::integer              AS num_facturas_20,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '21' THEN fc.monto_total - fc.iva END) AS total_21,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '21' THEN 1 END)::integer              AS num_facturas_21,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '22' THEN fc.monto_total - fc.iva END) AS total_22,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '22' THEN 1 END)::integer              AS num_facturas_22,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '23' THEN fc.monto_total - fc.iva END) AS total_23,
               SUM(CASE WHEN LEFT(fc.hora, 2) = '23' THEN 1 END)::integer              AS num_facturas_23,
               SUM(fc.monto_total - fc.iva)                                            AS total,
               SUM(1)::integer                                                         AS num_facturas
        FROM puntos_venta.facturas_cabecera fc
        WHERE LEFT(fc.referencia, 3) = p_bodega
          AND fc.fecha BETWEEN p_fecha_inicial AND p_fecha_final
          AND NULLIF(fc.status, '') IS NULL
          AND fc.hora IS NOT NULL
        GROUP BY fc.fecha, fc.terminal
        ORDER BY fc.fecha, fc.terminal;
END;

$function$
;


SELECT *
FROM puntos_venta.reporte_ventas_x_hora('021', '2025-01-01', '2025-01-02');

WITH total AS (SELECT SUM(total_08) AS total_08,
                      SUM(total_09) AS total_09,
                      SUM(total_10) AS total_10,
                      SUM(total_11) AS total_11,
                      SUM(total_12) AS total_12,
                      SUM(total_13) AS total_13,
                      SUM(total_14) AS total_14,
                      SUM(total_15) AS total_15,
                      SUM(total_16) AS total_16,
                      SUM(total_17) AS total_17,
                      SUM(total_18) AS total_18,
                      SUM(total_19) AS total_19,
                      SUM(total_20) AS total_20,
                      SUM(total_21) AS total_21,
                      SUM(total_22) AS total_22,
                      SUM(total_23) AS total_23,
                      SUM(total)    AS total
               FROM puntos_venta.reporte_ventas_x_hora('021', '2025-01-01', '2025-01-02'))
SELECT (total_08 / total * 100) AS porcentaje_08,
       (total_09 / total * 100) AS porcentaje_09,
       (total_10 / total * 100) AS porcentaje_10,
       (total_11 / total * 100) AS porcentaje_11,
       (total_12 / total * 100) AS porcentaje_12,
       (total_13 / total * 100) AS porcentaje_13,
       (total_14 / total * 100) AS porcentaje_14,
       (total_15 / total * 100) AS porcentaje_15,
       (total_16 / total * 100) AS porcentaje_16,
       (total_17 / total * 100) AS porcentaje_17,
       (total_18 / total * 100) AS porcentaje_18,
       (total_19 / total * 100) AS porcentaje_19,
       (total_20 / total * 100) AS porcentaje_20,
       (total_21 / total * 100) AS porcentaje_21,
       (total_22 / total * 100) AS porcentaje_22,
       (total_23 / total * 100) AS porcentaje_23
FROM total;