SELECT fc.fecha, fc.terminal, LEFT(fc.hora, 2), SUM(fc.monto_total - fc.iva) AS total, COUNT(*) AS num_facturas
FROM puntos_venta.facturas_cabecera fc
WHERE LEFT(fc.referencia, 3) = '021'
  AND fc.fecha BETWEEN '2025-01-01' AND '2025-01-02'
  AND NULLIF(fc.status, '') IS NULL
GROUP BY fecha, terminal, LEFT(hora, 2);


SELECT fecha,
       terminal,
       "08",
       "09",
       "10",
       "11",
       "12",
       "13",
       "14",
       "15",
       "16",
       "17",
       "18",
       "19",
       "20",
       "21",
       "22",
       "23"
FROM crosstab(
         -- Consulta de datos (vertical) con clave compuesta
             'WITH datos AS (
                SELECT fc.fecha, fc.terminal, LEFT(fc.hora, 2) AS hora, SUM(fc.monto_total - fc.iva) AS total
                FROM puntos_venta.facturas_cabecera fc
                WHERE LEFT(fc.referencia, 3) = ''021''
                  AND fc.fecha BETWEEN ''2025-01-01'' AND ''2025-01-02''
                  AND NULLIF(fc.status, '''') IS NULL
                  AND fc.hora IS NOT NULL
                GROUP BY fc.fecha, fc.terminal, LEFT(fc.hora, 2)
              )
              SELECT fecha || ''|'' || terminal AS row_name, fecha, terminal, hora, total
              FROM datos
              ORDER BY fecha, terminal, hora',
         -- Consulta de categorías (horas fijas de 08 a 23)
             'SELECT lpad(generate_series(8, 23)::TEXT, 2, ''0'') AS hora ORDER BY hora'
     ) AS final_result(
                       row_name TEXT,
                       fecha DATE,
                       terminal TEXT,
                       "08" NUMERIC, "09" NUMERIC, "10" NUMERIC, "11" NUMERIC, "12" NUMERIC, "13" NUMERIC,
                       "14" NUMERIC, "15" NUMERIC, "16" NUMERIC, "17" NUMERIC, "18" NUMERIC, "19" NUMERIC,
                       "20" NUMERIC, "21" NUMERIC, "22" NUMERIC, "23" NUMERIC
    );

SELECT DISTINCT terminal
FROM puntos_venta.facturas_cabecera fc
WHERE LEFT(fc.referencia, 3) = '021'
  AND fc.fecha BETWEEN '2025-01-01' AND '2025-01-02'
  AND NULLIF(fc.status, '') IS NULL;


SELECT fc.fecha, fc.terminal, LEFT(fc.hora, 2) AS hora, SUM(fc.monto_total - fc.iva) AS total
FROM puntos_venta.facturas_cabecera fc
WHERE LEFT(fc.referencia, 3) = '021'
  AND fc.fecha BETWEEN '2025-01-01' AND '2025-01-02'
  AND NULLIF(fc.status, '') IS NULL
GROUP BY fc.fecha, fc.terminal, LEFT(fc.hora, 2)
ORDER BY fc.fecha, fc.terminal, LEFT(fc.hora, 2);

WITH datos AS (SELECT fc.fecha, fc.terminal, LEFT(fc.hora, 2) AS hora, SUM(fc.monto_total - fc.iva) AS total
               FROM puntos_venta.facturas_cabecera fc
               WHERE LEFT(fc.referencia, 3) = '021'
                 AND fc.fecha BETWEEN '2025-01-01' AND '2025-01-02'
                 AND NULLIF(fc.status, '') IS NULL
                 AND fc.hora IS NOT NULL
               GROUP BY fc.fecha, fc.terminal, LEFT(fc.hora, 2))
SELECT fecha, terminal, hora, total
FROM datos
ORDER BY fecha, terminal, hora


SELECT fc.fecha,
       fc.terminal,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '08' THEN fc.monto_total - fc.iva END) AS total_08,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '08' THEN 1 END)                       AS num_facturas_08,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '09' THEN fc.monto_total - fc.iva END) AS total_09,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '09' THEN 1 END)                       AS num_facturas_09,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '10' THEN fc.monto_total - fc.iva END) AS total_10,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '10' THEN 1 END)                       AS num_facturas_10,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '11' THEN fc.monto_total - fc.iva END) AS total_11,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '11' THEN 1 END)                       AS num_facturas_11,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '12' THEN fc.monto_total - fc.iva END) AS total_12,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '12' THEN 1 END)                       AS num_facturas_12,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '13' THEN fc.monto_total - fc.iva END) AS total_13,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '13' THEN 1 END)                       AS num_facturas_13,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '14' THEN fc.monto_total - fc.iva END) AS total_14,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '14' THEN 1 END)                       AS num_facturas_14,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '15' THEN fc.monto_total - fc.iva END) AS total_15,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '15' THEN 1 END)                       AS num_facturas_15,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '16' THEN fc.monto_total - fc.iva END) AS total_16,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '16' THEN 1 END)                       AS num_facturas_16,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '17' THEN fc.monto_total - fc.iva END) AS total_17,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '17' THEN 1 END)                       AS num_facturas_17,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '18' THEN fc.monto_total - fc.iva END) AS total_18,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '18' THEN 1 END)                       AS num_facturas_18,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '19' THEN fc.monto_total - fc.iva END) AS total_19,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '19' THEN 1 END)                       AS num_facturas_19,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '20' THEN fc.monto_total - fc.iva END) AS total_20,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '20' THEN 1 END)                       AS num_facturas_20,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '21' THEN fc.monto_total - fc.iva END) AS total_21,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '21' THEN 1 END)                       AS num_facturas_21,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '22' THEN fc.monto_total - fc.iva END) AS total_22,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '22' THEN 1 END)                       AS num_facturas_22,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '23' THEN fc.monto_total - fc.iva END) AS total_23,
       SUM(CASE WHEN LEFT(fc.hora, 2) = '23' THEN 1 END)                       AS num_facturas_23,
       SUM(fc.monto_total - fc.iva)                                            AS total,
       SUM(1)                                                                  AS num_facturas
FROM puntos_venta.facturas_cabecera fc
WHERE LEFT(fc.referencia, 3) = '021'
  AND fc.fecha BETWEEN '2025-01-01' AND '2025-01-15'
  AND NULLIF(fc.status, '') IS NULL
  AND fc.hora IS NOT NULL
GROUP BY fc.fecha, fc.terminal
ORDER BY fc.fecha, fc.terminal;


SELECT fecha,
       hora,
       SUM(monto_total - iva) AS total_ventas,
       COUNT(*)               AS numero_facturas
FROM puntos_venta.facturas_cabecera
WHERE status IS NULL -- Assuming only active invoices are considered
GROUP BY fecha, hora
ORDER BY total_ventas DESC
LIMIT 1;


16:18:51
SELECT *,
       IIF(total_08 IS NULL OR total_08 = 0 OR total IS NULL OR total = 0, 0,
           (total_08 / total * 100))::number                 AS InternalReportField0,
       CASE WHEN (num_facturas_10 IS NULL) THEN 1 ELSE 0 END AS InternalReportField1,
       CASE WHEN (total_20 > 0) THEN 1 ELSE 0 END            AS InternalReportField10,
       CASE WHEN (num_facturas_20 IS NULL) THEN 1 ELSE 0 END AS InternalReportField11,
       CASE WHEN (total_21 > 0) THEN 1 ELSE 0 END            AS InternalReportField12,
       CASE WHEN (num_facturas_12 IS NULL) THEN 1 ELSE 0 END AS InternalReportField13,
       CASE WHEN (num_facturas_21 IS NULL) THEN 1 ELSE 0 END AS InternalReportField14,
       CASE WHEN (total_22 > 0) THEN 1 ELSE 0 END            AS InternalReportField15,
       CASE WHEN (num_facturas_22 IS NULL) THEN 1 ELSE 0 END AS InternalReportField16,
       CASE WHEN (total_23 > 0) THEN 1 ELSE 0 END            AS InternalReportField17,
       CASE WHEN (num_facturas_23 IS NULL) THEN 1 ELSE 0 END AS InternalReportField18,
       CASE WHEN (total > 0) THEN 1 ELSE 0 END               AS InternalReportField19,
       CASE WHEN (num_facturas_11 IS NULL) THEN 1 ELSE 0 END AS InternalReportField2,
       CASE WHEN (num_facturas IS NULL) THEN 1 ELSE 0 END    AS InternalReportField20,
       CASE WHEN (total_13 > 0) THEN 1 ELSE 0 END            AS InternalReportField21,
       CASE WHEN (num_facturas_13 IS NULL) THEN 1 ELSE 0 END AS InternalReportField22,
       CASE WHEN (total_14 > 0) THEN 1 ELSE 0 END            AS InternalReportField23,
       CASE WHEN (num_facturas_14 IS NULL) THEN 1 ELSE 0 END AS InternalReportField24,
       CASE WHEN (total_15 > 0) THEN 1 ELSE 0 END            AS InternalReportField25,
       CASE WHEN (num_facturas_15 IS NULL) THEN 1 ELSE 0 END AS InternalReportField26,
       CASE WHEN (total_16 > 0) THEN 1 ELSE 0 END            AS InternalReportField27,
       CASE WHEN (num_facturas_08 IS NULL) THEN 1 ELSE 0 END AS InternalReportField28,
       CASE WHEN (num_facturas_09 IS NULL) THEN 1 ELSE 0 END AS InternalReportField29,
       CASE WHEN (num_facturas_16 IS NULL) THEN 1 ELSE 0 END AS InternalReportField3,
       CASE WHEN (total_11 > 0) THEN 1 ELSE 0 END            AS InternalReportField30,
       CASE WHEN (total_08 > 0) THEN 1 ELSE 0 END            AS InternalReportField31,
       CASE WHEN (total_09 > 0) THEN 1 ELSE 0 END            AS InternalReportField32,
       CASE WHEN (total_10 > 0) THEN 1 ELSE 0 END            AS InternalReportField33,
       CASE WHEN (total_12 > 0) THEN 1 ELSE 0 END            AS InternalReportField34,
       CASE WHEN (total_17 > 0) THEN 1 ELSE 0 END            AS InternalReportField4,
       CASE WHEN (num_facturas_17 IS NULL) THEN 1 ELSE 0 END AS InternalReportField5,
       CASE WHEN (total_18 > 0) THEN 1 ELSE 0 END            AS InternalReportField6,
       CASE WHEN (num_facturas_18 IS NULL) THEN 1 ELSE 0 END AS InternalReportField7,
       CASE WHEN (total_19 > 0) THEN 1 ELSE 0 END            AS InternalReportField8,
       CASE WHEN (num_facturas_19 IS NULL) THEN 1 ELSE 0 END AS InternalReportField9
FROM (

