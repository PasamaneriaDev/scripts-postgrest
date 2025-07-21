-- DROP FUNCTION auditoria.reporte_retenciones_x_cliente(p_cuenta varchar, p_fecha_desde date, p_fecha_hasta date)

CREATE OR REPLACE FUNCTION auditoria.reporte_retenciones_x_cliente(p_cuenta varchar, p_fecha_desde date,
                                                                   p_fecha_hasta date)
    RETURNS TABLE
            (
                vendedor           varchar,
                cliente            varchar,
                nombre             varchar,
                cedula_ruc         varchar,
                serie_retencion    text,
                num_retencion      text,
                creacion_fecha     date,
                fecha_retencion    date,
                serie_factura      text,
                num_factura        text,
                base_imp           numeric,
                valor_retencion    numeric,
                cuenta             varchar,
                grupo_contabilidad varchar,
                transaccion        varchar
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT c.vendedor,
               c.cliente,
               cli.nombre,
               cli.cedula_ruc,
               LEFT(c.recibo, 6)              AS serie_retencion,
               SUBSTRING(c.recibo, 7, 9)      AS num_retencion,
               c.creacion_fecha,
               c.fecha_retencion,
               LEFT(fc.referencia, 6)         AS serie_factura,
               SUBSTRING(fc.referencia, 7, 9) AS num_factura,
               (fc.monto_total - fc.iva)      AS base_imp,
               c.monto_pago                   AS valor_retencion,
               dd.cuenta,
               dd.grupo_contabilidad,
               c.transaccion
        FROM cuentas_cobrar.cobros c
                 JOIN cuentas_cobrar.clientes cli ON c.cliente = cli.codigo
                 JOIN cuentas_cobrar.facturas_cabecera fc ON fc.referencia = c.referencia
                 JOIN LATERAL ( SELECT d.cuenta, d.grupo_contabilidad
                                FROM cuentas_cobrar.distribucion d
                                WHERE d.numero_transaccion = c.transaccion
                                ORDER BY d.secuencia
                                LIMIT 1 ) dd ON TRUE
        WHERE c.creacion_fecha BETWEEN p_fecha_desde AND p_fecha_hasta
          AND c.es_retencion
          AND (dd.cuenta = p_cuenta OR p_cuenta = '')
        ORDER BY c.creacion_fecha, c.transaccion;
END;
$function$
;