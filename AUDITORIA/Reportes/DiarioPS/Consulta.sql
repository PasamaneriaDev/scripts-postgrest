-- DROP FUNCTION auditoria.reporte_diariops(date, date, varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_diariops(p_fecha_ini date, p_fecha_fin date,
                                                      p_cuenta_ini character varying, p_cuenta_fin character varying,
                                                      p_grupo_ini character varying, p_grupo_fin character varying,
                                                      p_ordenado character varying)
    RETURNS TABLE
            (
                cuenta                 character varying,
                descripcion_cuenta     character varying,
                fecha                  date,
                tipo                   text,
                cliente                character varying,
                numero_factura         character varying,
                referencia             character varying,
                tipo_pago              character varying,
                tipo_transaccion       character varying,
                grupo_contabilidad     character varying,
                monto                  numeric,
                lote                   character varying,
                tipo_tarjeta           character varying,
                codigo_red_adquiriente character varying,
                cedula_ruc             character varying
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE

BEGIN
    RETURN QUERY
        SELECT d.cuenta,
               c.descripcion                                              AS descripcion_cuenta,
               d.fecha,
               CASE
                   WHEN COALESCE(fc.tipo_transaccion, '') = '' THEN 'Factura'
                   WHEN fc.tipo_transaccion = 'C' THEN 'Nota Crédito' END AS tipo,
               fc.cliente,
               fc.factura,
               d.numero_transaccion,
               fc.tipo_pago,
               d.tipo_transaccion,
               d.grupo_contabilidad,
               d.monto,
               pt.lote,
               pt.tipo_tarjeta,
               CASE
                   WHEN pt.codigo_red_adquiriente = '01' THEN 'DATAFAST'
                   WHEN pt.codigo_red_adquiriente = '02' THEN 'MEDIANET'
                   WHEN pt.codigo_red_adquiriente = '03' THEN 'AUSTRO'
                   ELSE pt.codigo_red_adquiriente END                     AS codigo_red_adquiriente,
               pt.cedula_ruc
        FROM puntos_venta.distribucion d
                 LEFT JOIN contabilidad_general.cuentas c
                           ON c.cuenta = d.cuenta
                 LEFT JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = d.numero_transaccion
                 LEFT JOIN cuentas_cobrar.pagos_tarjeta pt ON pt.referencia = fc.referencia AND pt.valor = d.monto
        WHERE d.fecha BETWEEN p_fecha_ini AND p_fecha_fin
          AND d.monto <> 0
          AND (p_cuenta_ini = '' OR d.cuenta >= p_cuenta_ini)
          AND (p_cuenta_fin = '' OR d.cuenta <= p_cuenta_fin)
          AND (p_grupo_ini = '' OR d.grupo_contabilidad >= p_grupo_ini)
          AND (p_grupo_fin = '' OR d.grupo_contabilidad <= p_grupo_fin)
        ORDER BY CASE WHEN p_ordenado = 'CUENTA' THEN d.cuenta END,
                 CASE WHEN p_ordenado = 'FECHA' THEN d.fecha END,
                 d.numero_transaccion, CASE WHEN p_ordenado = 'FACTURA' THEN d.cuenta END;
END;
$function$
;


SELECT *
FROM
    auditoria.reporte_diariops('2023-01-01', '2023-12-31', '', '', '', '', 'CUENTA');