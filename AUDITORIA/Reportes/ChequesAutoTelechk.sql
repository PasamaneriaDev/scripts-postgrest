-- DROP FUNCTION auditoria.reporte_cheques_autor_telechk(p_periodo_ini varchar, p_periodo_fin varchar, p_almacen varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_cheques_autor_telechk(p_periodo_ini varchar,
                                                                            p_periodo_fin varchar,
                                                                            p_almacen varchar)
    RETURNS TABLE
            (
                referencia varchar,
                fecha_pago date,
                hora_pago  varchar,
                monto_pago numeric,
                cheque     text,
                banco      text,
                cuenta     text,
                telecheck  text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT p.referencia,
               p.fecha_pago,
               p.hora_pago,
               p.monto_pago,
               LEFT(p.codigo_documento, 7)       AS cheque,
               LEFT(p.verificacion, 8)           AS banco,
               SUBSTR(p.codigo_documento, 8, 12) AS cuenta,
               SUBSTR(p.verificacion, 9, 7)      AS telecheck
        FROM puntos_venta.pagos p
        WHERE p.codigo_pago = 'E'
          AND COALESCE(SUBSTR(p.verificacion, 9, 7), '') <> ''
          AND TO_CHAR(p.fecha_pago, 'YYYYMM') BETWEEN p_periodo_ini AND p_periodo_fin
          AND (p_almacen = '' OR LEFT(p.referencia, 3) = p_almacen);
END;
$function$
;


