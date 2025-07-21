-- DROP FUNCTION auditoria.reporte_movimientos_inventario_periodo(p_periodo varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_movimientos_inventario_periodo(p_periodo varchar)
    RETURNS TABLE
            (
                grupo                 text,
                ini_anterior          numeric,
                trans_anterior        numeric,
                ingresos              numeric,
                egresos               numeric,
                devolucion            numeric,
                gastos                numeric,
                inv_final_ant_ajustes numeric,
                ajustes               numeric,
                ini_actual            numeric,
                trans_actual          numeric,
                diferencia            numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_periodo_anterior varchar;
BEGIN
    -- calcula el periodo anterior al periodo actual
    v_periodo_anterior := TO_CHAR(TO_DATE(p_periodo, 'YYYYMM') - INTERVAL '1 month', 'YYYYMM');

    RETURN QUERY
        WITH periodos AS (SELECT ih.periodo,
                                 CASE
                                     WHEN LEFT(ih.ITEM, 1) IN ('1', '7') OR LEFT(ih.item, 2) = '01' THEN 'CONF'
                                     WHEN LEFT(ih.ITEM, 1) = '2' THEN 'CINT'
                                     WHEN LEFT(ih.ITEM, 1) = '3' THEN 'ELAS'
                                     WHEN LEFT(ih.ITEM, 1) = '4' THEN 'HIL4'
                                     WHEN LEFT(ih.ITEM, 1) = '5' THEN 'CALC'
                                     WHEN LEFT(ih.ITEM, 1) = '6' THEN 'ENCA'
                                     WHEN LEFT(ih.ITEM, 1) SIMILAR TO '[79]%' THEN 'SEDA'
                                     WHEN LEFT(ih.ITEM, 1) IN ('8', 'B', 'X') THEN 'HILB'
                                     WHEN NOT ih.item ~ '^[123456789BX]' THEN 'WIPE'
                                     WHEN LEFT(ih.ITEM, 1) = '10' THEN 'PROM'
                                     ELSE 'OTROS' END grupo,
                                 ih.existencia,
                                 ih.transito,
                                 ih.costo_promedio
                          FROM control_inventarios.items_historico ih
                          WHERE ih.periodo IN (p_periodo, v_periodo_anterior)
                            AND ih.nivel = 'ILOC'
                            AND ((ih.es_vendible AND ih.es_fabricado AND ih.item ~ '^[0123456789BXZ]') OR
                                 LEFT(ih.item, 2) IN ('1U', '55'))
                            AND ih.bodega ~ '^[0123456789CGMZPI]'
                            AND (SUBSTRING(ih.bodega FROM 2 FOR 1) IN
                                 ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'R'))
                            AND
                              RIGHT(ih.bodega, 1) IN ('', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'C', 'Q')),
             per_actual AS (SELECT p.grupo,
                                   SUM(p.existencia * p.costo_promedio) inivi,
                                   SUM(p.transito * p.costo_promedio)   trans
                            FROM periodos p
                            WHERE p.periodo = p_periodo
                            GROUP BY p.grupo),
             per_ant AS (SELECT p.grupo,
                                SUM(p.existencia * p.costo_promedio) inivi,
                                SUM(p.transito * p.costo_promedio)   trans
                         FROM periodos p
                         WHERE p.periodo = v_periodo_anterior
                         GROUP BY p.grupo),
             transacc AS (SELECT CASE
                                     WHEN LEFT(i.ITEM, 1) IN ('1', '7') OR LEFT(i.item, 2) = '01' THEN 'CONF'
                                     WHEN LEFT(i.ITEM, 1) = '2' THEN 'CINT'
                                     WHEN LEFT(i.ITEM, 1) = '3' THEN 'ELAS'
                                     WHEN LEFT(i.ITEM, 1) = '4' THEN 'HIL4'
                                     WHEN LEFT(i.ITEM, 1) = '5' THEN 'CALC'
                                     WHEN LEFT(i.ITEM, 1) = '6' THEN 'ENCA'
                                     WHEN i.ITEM ~ '^[79]' THEN 'SEDA'
                                     WHEN LEFT(i.ITEM, 1) IN ('8', 'B', 'X') THEN 'HILB'
                                     WHEN i.ITEM ~ '^[9Z]' THEN 'WIPE'
                                     WHEN LEFT(i.ITEM, 1) = '10' THEN 'PROM'
                                     END             grupo,
                                 SUM(CASE
                                         WHEN t.tipo_movimiento IN ('INGR PT', 'COMP EXT')
                                             THEN t.cantidad * t.costo
                                         ELSE 0 END) ingresos,
                                 SUM(CASE
                                         WHEN t.tipo_movimiento IN ('VTAS MAY', 'DEVO MAY', 'VTAS ALM', 'DEVO ALM')
                                             THEN t.cantidad * t.costo
                                         ELSE 0 END) egresos,
                                 SUM(CASE
                                         WHEN t.tipo_movimiento IN ('DEVO PLAN')
                                             THEN t.cantidad * t.costo
                                         ELSE 0 END) devolucion,
                                 SUM(CASE
                                         WHEN t.tipo_movimiento IN ('EGRESO', 'REINGRES')
                                             THEN t.cantidad * t.costo
                                         ELSE 0 END) gastos,
                                 SUM(CASE
                                         WHEN t.tipo_movimiento IN
                                              ('AJUS CANT-', 'AJUS CANT+', 'CA', 'AJUS COST-', 'AJUS COST+')
                                             THEN t.cantidad * t.costo
                                         ELSE 0 END) ajustes
                          FROM control_inventarios.transacciones t
                                   JOIN control_inventarios.items i ON i.item = t.item
                          WHERE t.periodo = p_periodo
                            AND ((i.es_vendible AND i.es_fabricado) OR LEFT(i.item, 2) IN ('1U', '55'))
                            AND i.item ~ '^[0123456789BZ]'
                            AND t.tipo_movimiento IN
                                ('INGR PT', 'COMP EXT', 'DEVO PLAN', 'VTAS MAY', 'DEVO MAY', 'VTAS ALM', 'DEVO ALM',
                                 'EGRESO', 'REINGRES', 'AJUS CANT-', 'AJUS CANT+', 'CA', 'AJUS COST-', 'AJUS COST+')
                          GROUP BY grupo)
        SELECT a.grupo,
               b.inivi                                                                AS ini_anterior,
               b.trans                                                                AS trans_anterior,
               c.ingresos,
               c.egresos,
               c.devolucion,
               c.gastos,
               (b.inivi + b.trans + c.ingresos + c.egresos + c.devolucion + c.gastos) AS inv_final_ant_ajustes,
               c.ajustes,
               a.inivi                                                                AS ini_actual,
               a.trans                                                                AS trans_actual,
               (b.inivi + b.trans + c.ingresos + c.egresos + c.devolucion + c.gastos + c.ajustes) -
               (a.inivi + a.trans)                                                    AS diferencia
        FROM per_actual a
                 JOIN per_ant b ON a.grupo = b.grupo
                 JOIN transacc c ON a.grupo = c.grupo;
END;
$function$
;


