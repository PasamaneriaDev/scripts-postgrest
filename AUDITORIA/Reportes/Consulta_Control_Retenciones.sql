-- DROP FUNCTION cuentas_cobrar.retenciones_reporte_control_auditoria(fecha_inicial date, fecha_final date)

CREATE OR REPLACE FUNCTION cuentas_cobrar.retenciones_reporte_control_auditoria(fecha_inicial date, fecha_final date)
    RETURNS TABLE
            (
                vendedor               varchar,
                cliente                varchar,
                referencia             varchar,
                nombre                 varchar,
                cedula_ruc             varchar,
                tipo_retencion         varchar,
                recibo                 varchar,
                autorizacion_retencion varchar,
                fecha_retencion        date,
                creacion_fecha         date,
                factura                varchar,
                base_retencion         numeric,
                porcentaje_retencion   numeric,
                monto_pago             numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        SELECT c.vendedor,
               c.cliente,
               c.referencia,
               cli.nombre,
               cli.cedula_ruc,
               c.tipo_retencion,
               c.recibo,
               c.autorizacion_retencion,
               c.fecha_retencion,
               c.creacion_fecha,
               fc.factura,
               ROUND((fc.monto_total - fc.iva), 2) AS base_retencion,
               c.porcentaje_retencion,
               c.monto_pago
        FROM cuentas_cobrar.cobros c
                 LEFT JOIN cuentas_cobrar.clientes cli ON c.cliente = cli.codigo
                 LEFT JOIN cuentas_cobrar.facturas_cabecera fc ON fc.referencia = c.referencia
        WHERE c.creacion_fecha BETWEEN fecha_inicial AND fecha_final
          AND c.es_retencion
        ORDER BY c.recibo;
END;
$function$
;


