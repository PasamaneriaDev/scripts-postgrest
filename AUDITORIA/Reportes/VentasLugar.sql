-- DROP FUNCTION auditoria.reporte_ventas_x_lugar(p_periodo varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_ventas_x_lugar(p_periodo varchar)
    RETURNS TABLE
            (
                referencia varchar,
                monto      numeric,
                fecha      date,
                lugar      varchar
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    RETURN QUERY
        SELECT x.referencia, SUM(x.monto), x.fecha, x.lugar
        FROM ((SELECT fd.referencia,
                      fd.total_precio                                                         AS monto,
                      fd.fecha,
                      CASE WHEN ib.lugar_venta IS NULL THEN fd.bodega ELSE ib.lugar_venta END AS lugar
               FROM puntos_venta.facturas_detalle_ventas fd
                        LEFT JOIN control_inventarios.id_bodegas ib ON ib.bodega = fd.bodega
               WHERE fd.periodo = p_periodo)
              UNION ALL
              (SELECT fd.referencia,
                      fd.total_precio AS monto,
                      fd.fecha,
                      CASE
                          WHEN fd.cliente = '200100' THEN 'CASA TOSI'
                          WHEN fd.cliente = '200101' THEN 'MERCANTIL'
                          WHEN fd.bodega = '042' THEN 'ROMAN'
                          WHEN fd.bodega = '003' THEN 'DONACION'
                          WHEN LEFT(r.tipo_comision, 1) = 'C' THEN 'AGENTES CU'
                          WHEN LEFT(r.tipo_comision, 1) = 'Q' THEN 'AGENTES QU'
                          WHEN fd.vendedor = 'VC' THEN 'VTA. CATAL'
                          ELSE 'FACTURA'
                          END         AS lugar
               FROM cuentas_cobrar.facturas_detalle_ventas fd
                        LEFT JOIN sistema.reglas r ON fd.vendedor = r.codigo
                   AND r.regla = 'SLSPERS'
                   AND LEFT(r.tipo_comision, 1) IN ('C', 'Q')
                   AND SUBSTRING(r.tipo_comision, 2, 1) <> 'X'
               WHERE fd.periodo = p_periodo)) x
        GROUP BY x.referencia, x.fecha, x.lugar
        ORDER BY x.referencia;

END;
$function$
;


