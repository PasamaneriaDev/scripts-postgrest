-- DROP FUNCTION auditoria.reporte_ventas_x_cliente(p_cedula varchar, p_fecha_desde date, p_fecha_hasta date)

CREATE OR REPLACE FUNCTION auditoria.reporte_ventas_x_cliente(p_cedula varchar, p_almacen varchar, p_fecha_desde date,
                                                              p_fecha_hasta date)
    RETURNS TABLE
            (
                cliente        text,
                tipo_documento text,
                referencia     varchar,
                factura        varchar,
                fecha          date,
                iva            numeric,
                descuento      numeric,
                monto_total    numeric,
                pago           text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    RETURN QUERY
        SELECT CONCAT(c.nombres, ' ', c.apellidos)                       AS cliente,
               CASE WHEN fc.tipo_documento = 'C' THEN 'NC' ELSE 'FA' END AS tipo_documento,
               fc.referencia,
               fc.factura,
               fc.fecha,
               fc.iva,
               fc.descuento,
               fc.monto_total,
               CASE
                   WHEN LEFT(fc.tipo_pago, 1) = 'B' THEN 'EFECTIVO'
                   WHEN LEFT(fc.tipo_pago, 1) = '2' THEN 'DINERS'
                   WHEN LEFT(fc.tipo_pago, 1) = '5' THEN 'MASTERCARD'
                   WHEN LEFT(fc.tipo_pago, 1) = '6' THEN 'VISA'
                   WHEN LEFT(fc.tipo_pago, 1) = '7' THEN 'AMERICAN'
                   WHEN LEFT(fc.tipo_pago, 1) = 'E' THEN 'CHEQUE'
                   WHEN LEFT(fc.tipo_pago, 1) = 'Q' THEN 'VALE'
                   WHEN LEFT(fc.tipo_pago, 1) = 'L' THEN 'CREDITO'
                   WHEN LEFT(fc.tipo_pago, 1) = '3' THEN 'CUOTA FACIL'
                   END                                                   AS pago
        FROM puntos_venta.facturas_cabecera fc
                 JOIN puntos_venta.clientes c ON c.cedula_ruc = fc.cedula_ruc
        WHERE fc.cedula_ruc = p_cedula
          AND fc.fecha BETWEEN p_fecha_desde AND p_fecha_hasta
          AND (left(fc.referencia, 3) = p_almacen OR p_almacen = '');

END;
$function$
;


