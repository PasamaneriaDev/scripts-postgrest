SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3'



SELECT *
FROM fe_comprobantes_recibidos t1
         INNER JOIN LATERAL
    (
    SELECT ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 0 THEN fdr.baseimponibleiva END), .0), 2)  AS bi_0
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 5 THEN fdr.baseimponibleiva END), .0), 2)  AS bi_5
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 5 THEN fdr.valoriva END), .0), 2)          AS iva_5
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 12 THEN fdr.baseimponibleiva END), .0), 2) AS bi_12
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 12 THEN fdr.valoriva END), .0), 2)         AS iva_12
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 15 THEN fdr.baseimponibleiva END), .0), 2) AS bi_15
         , ROUND(COALESCE(SUM(CASE WHEN fdr.tarifaiva = 15 THEN fdr.valoriva END), .0), 2)         AS iva_15
    FROM public.fe_detalle_recibidos fdr
    WHERE TRUE
      AND fdr.ruc_empresa = t1.ruc_empresa
      AND fdr.ruc_emisor = t1.ruc_emisor
      AND fdr.documento = t1.documento
      AND fdr.establecimiento = t1.establecimiento
      AND fdr.puntoemision = t1.punto_emision
      AND fdr.secuencial = t1.secuencial
    ) bi ON TRUE
WHERE t1.estado_comprobante = 'R'
AND t1.documento = '01'

SELECT t1.documento
FROM fe_comprobantes_recibidos t1
WHERE t1.estado_comprobante = 'R'
GROUP BY  t1.documento

SELECT *
FROM cuentas_pagar.proveedores p
WHERE cedula_ruc = '0502345887001' --013996