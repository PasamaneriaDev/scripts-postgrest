-- DROP FUNCTION auditoria.reporte_movimientos_inventario_periodo_ajustes(varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_movimientos_inventario_periodo_ajustes(p_periodo character varying)
    RETURNS TABLE
            (
                bodega character varying,
                grupo  text,
                valor  numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    RETURN QUERY
        SELECT t.bodega,
               CASE
                   WHEN LEFT(i.ITEM, 1) IN ('1', '7') OR LEFT(i.item, 2) = '01' THEN 'CONFECCION'
                   WHEN LEFT(i.ITEM, 1) = '2' THEN 'CINTAS'
                   WHEN LEFT(i.ITEM, 1) = '3' THEN 'ELASTICO'
                   WHEN LEFT(i.ITEM, 1) = '4' THEN 'HILOS 4'
                   WHEN LEFT(i.ITEM, 1) = '5' THEN 'CALCETIN'
                   WHEN LEFT(i.ITEM, 1) = '6' THEN 'ENCAJES'
                   WHEN i.ITEM ~ '^[79]' THEN 'SEDA'
                   WHEN LEFT(i.ITEM, 1) IN ('8', 'B', 'X') THEN 'HILOS B'
                   WHEN i.ITEM ~ '^[9Z]' THEN 'WIPE'
                   WHEN LEFT(i.ITEM, 1) = '0' THEN 'PROMO'
                   END                      grupo,
               SUM(t.cantidad * t.costo) AS valor
        FROM control_inventarios.transacciones t
                 JOIN control_inventarios.items i ON t.item = i.item
        WHERE t.tipo_movimiento IN ('AJUS CANT-', 'AJUS CANT+', 'AJUS COST-', 'AJUS COST+')
          AND t.periodo = p_periodo
          AND ((i.es_vendible AND i.es_fabricado) OR LEFT(i.item, 2) IN ('1U', '55'))
          AND i.item ~ '^[0123456789BZ]'
        GROUP BY t.bodega, grupo;
END;
$function$
;
