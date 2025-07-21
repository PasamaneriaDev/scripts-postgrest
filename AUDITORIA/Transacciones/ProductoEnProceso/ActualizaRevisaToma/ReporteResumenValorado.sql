-- drop FUNCTION auditoria.reporte_resumen_valorados_proceso(p_bodega_ini varchar, p_bodega_fin varchar, p_periodo varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_resumen_valorados_proceso(p_bodega_ini varchar, p_bodega_fin varchar, p_periodo varchar)
    RETURNS TABLE
            (
                bodega                   CHARACTER VARYING,
                total_materia_prima      NUMERIC,
                total_mano_obra          NUMERIC,
                total_gastos_fabricacion NUMERIC,
                total_valor              NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        WITH transacciones_filtradas AS (SELECT tr.bodega, tr.transaccion, tr.cantidad, tr.item
                                         FROM inventario_proceso.transacciones tr
                                         WHERE tr.tipo_movimiento = 'AJUS PROC'
                                           AND tr.bodega >= p_bodega_ini
                                           AND tr.bodega <= p_bodega_fin
                                           AND (p_periodo = '' OR tr.periodo = p_periodo))
        SELECT x.bodega,
               SUM(x.valor_materia_prima)                                                            AS total_materia_prima,
               SUM(x.valor_mano_obra)                                                                AS total_mano_obra,
               SUM(x.valor_gastos_fabricacion)                                                       AS total_gastos_fabricacion,
               SUM(x.valor_materia_prima) + SUM(x.valor_mano_obra) + SUM(x.valor_gastos_fabricacion) AS total_valor
        FROM (SELECT t.bodega,
                     ABS(CASE WHEN d.cuenta = ib.cuenta_materia_prima THEN d.monto ELSE 0 END) AS valor_materia_prima,
                     ABS(CASE WHEN d.cuenta = ib.cuenta_mano_obra THEN d.monto ELSE 0 END)     AS valor_mano_obra,
                     ABS(CASE
                             WHEN d.cuenta = ib.cuenta_gastos_fabricacion THEN d.monto
                             ELSE 0 END)                                                       AS valor_gastos_fabricacion
              FROM transacciones_filtradas t
                       JOIN control_inventarios.id_bodegas ib ON t.bodega = ib.bodega
                       JOIN inventario_proceso.distribucion d ON d.transaccion = t.transaccion
              WHERE LEFT(t.item, 1) <> 'M'

              UNION ALL

              SELECT t.bodega,
                     ABS(i.costo_promedio * t.cantidad) AS valor_materia_prima,
                     0                                  AS valor_mano_obra,
                     0                                  AS valor_gastos_fabricacion
              FROM transacciones_filtradas t
                       JOIN inventario_proceso.items i ON t.item = i.item
              WHERE LEFT(t.item, 1) = 'M') AS x
        GROUP BY x.bodega;
END
$function$;


