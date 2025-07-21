/*
DROP FUNCTION auditoria.reporte_diarioic_detallado(p_modulo varchar, p_fecha_ini date,
                                                                p_fecha_fin date, p_cuenta_ini varchar,
                                                                p_cuenta_fin varchar, p_grupo_ini varchar,
                                                                p_grupo_fin varchar, p_ordenado varchar)
*/
CREATE OR REPLACE FUNCTION auditoria.reporte_diarioic_detallado(p_modulo varchar, p_fecha_ini date,
                                                                p_fecha_fin date, p_cuenta_ini varchar,
                                                                p_cuenta_fin varchar, p_grupo_ini varchar,
                                                                p_grupo_fin varchar, p_ordenado varchar)
    RETURNS table
            (
                cuenta             varchar,
                descripcion_cuenta varchar,
                fecha              date,
                item               varchar,
                descripcion        varchar,
                cantidad           numeric,
                tipo_movimiento    varchar,
                referencia         varchar,
                documento          varchar,
                grupo_contabilidad varchar,
                monto              numeric,
                modulo_r           varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE

BEGIN
    RETURN QUERY
        SELECT d.cuenta,
               c.descripcion AS descripcion_cuenta,
               d.fecha,
               t.item,
               i.descripcion,
               t.cantidad,
               t.tipo_movimiento,
               t.referencia,
               t.documento,
               d.grupo_contabilidad,
               d.monto,
               t.modulo
        FROM control_inventarios.distribucion d
                 left JOIN contabilidad_general.cuentas c
                      ON c.cuenta = d.cuenta
                 JOIN control_inventarios.transacciones t
                      ON d.transaccion = t.transaccion
                 JOIN control_inventarios.items i
                      ON i.item = t.item
        WHERE (p_modulo = 'TODO' OR t.modulo = p_modulo)
          AND d.fecha BETWEEN p_fecha_ini AND p_fecha_fin
          AND (p_cuenta_ini = '' OR d.cuenta >= p_cuenta_ini) --'11303010000000000'
          AND (p_cuenta_fin = '' OR d.cuenta <= p_cuenta_fin)
          AND (p_grupo_ini = '' OR d.grupo_contabilidad >= p_grupo_ini)
          AND (p_grupo_fin = '' OR d.grupo_contabilidad <= p_grupo_fin)
        ORDER BY CASE WHEN p_ordenado = 'CUENTA' THEN d.cuenta END,
                 CASE WHEN p_ordenado = 'GRUPO' THEN d.grupo_contabilidad END,
                 CASE WHEN p_ordenado = 'FECHA' THEN d.fecha END,
                 CASE WHEN p_ordenado = 'ORIGEN' THEN t.modulo END, i.item;
END;
$function$
