/*
 drop function puntos_venta.reporte_vale(p_vale character varying)

 */

CREATE OR REPLACE FUNCTION puntos_venta.reporte_vale(p_vale character varying)
    RETURNS TABLE
            (
                numero_vale character varying,
                numero_caja numeric,
                fecha_hora  text,
                vendedor    character varying,
                referencia  character varying,
                razon       character varying,
                saldo       numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT v.numero_vale,
               v.numero_caja,
               CASE
                   WHEN v.razon = 'Compra Prog. Anulada' THEN
                       v.fecha::text
                   ELSE p.fecha_pago || ' - ' || p.hora_pago END AS fecha_hora,
               v.vendedor,
               v.referencia,
               v.razon,
               v.saldo
        FROM puntos_venta.vales v
                 INNER JOIN puntos_venta.pagos p
                            ON v.referencia = p.referencia AND v.numero_vale = p.codigo_documento
        WHERE v.numero_vale = p_vale;

END
$function$
;

