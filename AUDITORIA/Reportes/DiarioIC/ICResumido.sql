/*
DROP FUNCTION auditoria.reporte_diarioic_resumido(p_modulo varchar, p_fecha_ini date,
                                                                p_fecha_fin date, p_cuenta_ini varchar,
                                                                p_cuenta_fin varchar, p_grupo_ini varchar,
                                                                p_grupo_fin varchar, p_ordenado varchar)
*/
CREATE OR REPLACE FUNCTION auditoria.reporte_diarioic_resumido(p_modulo varchar, p_fecha_ini date,
                                                               p_fecha_fin date, p_cuenta_ini varchar,
                                                               p_cuenta_fin varchar, p_grupo_ini varchar,
                                                               p_grupo_fin varchar, p_ordenado varchar)
    RETURNS table
            (
                grupo       varchar,
                fecha       date,
                modulo_r    varchar,
                cuenta      varchar,
                descripcion varchar,
                monto       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE

BEGIN
    RETURN QUERY
        SELECT CASE WHEN p_ordenado = 'GRUPO' THEN d.grupo_contabilidad END AS grupo,
               CASE WHEN p_ordenado = 'FECHA' THEN d.fecha END              AS fecha,
               CASE WHEN p_ordenado = 'ORIGEN' THEN t.modulo END            AS modulo_r,
               d.cuenta,
               c.descripcion,
               SUM(d.monto)                                                 AS monto
        FROM control_inventarios.distribucion d
                 left JOIN contabilidad_general.cuentas c
                      ON c.cuenta = d.cuenta
                 JOIN control_inventarios.transacciones t
                      ON d.transaccion = t.transaccion
        WHERE (p_modulo = 'TODO' OR t.modulo = p_modulo)
          AND d.fecha BETWEEN p_fecha_ini AND p_fecha_fin
          AND (p_cuenta_ini = '' OR d.cuenta >= p_cuenta_ini) --'11303010000000000'
          AND (p_cuenta_fin = '' OR d.cuenta <= p_cuenta_fin)
          AND (p_grupo_ini = '' OR d.grupo_contabilidad >= p_grupo_ini)
          AND (p_grupo_fin = '' OR d.grupo_contabilidad <= p_grupo_fin)
        GROUP BY CASE WHEN p_ordenado = 'GRUPO' THEN d.grupo_contabilidad END,
                 CASE WHEN p_ordenado = 'FECHA' THEN d.fecha END,
                 CASE WHEN p_ordenado = 'ORIGEN' THEN t.modulo END,
                 d.cuenta, c.descripcion
        ORDER BY CASE WHEN p_ordenado = 'GRUPO' THEN d.grupo_contabilidad END,
                 CASE WHEN p_ordenado = 'FECHA' THEN d.fecha END,
                 CASE WHEN p_ordenado = 'ORIGEN' THEN t.modulo END, d.cuenta;
END;
$function$
