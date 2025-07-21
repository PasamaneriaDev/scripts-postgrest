-- DROP FUNCTION cuentas_cobrar.retenciones_reporte_control_auditoria(p_periodo_ini varchar, p_periodo_fin varchar, p_tipo_item varchar, p_movimientos varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_transacciones_nivel_movimiento(p_periodo_ini varchar,
                                                                            p_periodo_fin varchar,
                                                                            p_tipo_item varchar,
                                                                            p_movimientos varchar)
    RETURNS TABLE
            (
                item                varchar,
                referencia          varchar,
                cantidad            numeric,
                fecha               date,
                cuenta_debito       varchar,
                descripcion_debito  varchar,
                monto_debito        numeric,
                cuenta_credito      varchar,
                descripcion_credito varchar,
                monto_credito       numeric,
                tipo_movimiento     varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_movimientos varchar[];
    v_tipo_item   varchar;
    v_corte_item  integer;
BEGIN
    /*
    --> Se recibe Los primeros 3 caracteres <--
    *** TIPOS DE ITEM (p_tipo_item)
    - HERRAMIENTAS
    - MAT.PRIMAS
    - REPUESTOS
    - SUMINISTROS
    - UTILES
    - COMISARIATO
    - CONSIGNACIO
    - DISPENSARIO
    *** TIPOS DE MOVIMIENTOS (p_movimientos)
    - CONSUMOS
    - COMPRAS
    - VENTAS
    - AJUSTES
    - IMPORTACIONES
    */

    v_movimientos = CASE
                        WHEN p_movimientos = 'CON' THEN
                            CASE
                                WHEN p_tipo_item = 'MAT' THEN ARRAY ['EGRESO', 'REINGRES', 'EGRE ORDE']
                                ELSE ARRAY ['EGRESO', 'REINGRES']
                                END
                        WHEN p_movimientos = 'COM' THEN ARRAY ['COMP EXT', 'DEVO EXT']
                        WHEN p_movimientos = 'VEN' THEN ARRAY ['VTAS MAY', 'VTAS ALM', 'DEVO ALM', 'DEVO MAY']
                        WHEN p_movimientos = 'IMP' THEN ARRAY ['COMP EXT', 'DEVO EXT']
                        ELSE ARRAY ['AJUS CANT-', 'AJUS CANT+', 'OJ', 'AJUS COST-', 'AJUS COST+', 'CA']
        END;

    IF p_tipo_item = 'CON' THEN
        v_corte_item = 2;
        v_tipo_item = '8C';
    ELSE
        v_corte_item = 1;
        v_tipo_item = LEFT(p_tipo_item, 1);
    END IF;

    RETURN QUERY
        SELECT t.item,
               t.referencia,
               t.cantidad,
               t.fecha,
               d.cuenta,
               cd.descripcion,
               d.monto,
               c.cuenta,
               cc.descripcion,
               c.monto,
               t.tipo_movimiento
        FROM control_inventarios.transacciones t
                 JOIN control_inventarios.distribucion d
                 JOIN contabilidad_general.cuentas cd ON d.cuenta = cd.cuenta
                      ON d.transaccion = t.transaccion AND d.monto < 0
                 JOIN control_inventarios.distribucion c
                      ON c.transaccion = t.transaccion AND c.monto > 0 AND ABS(d.monto) = c.monto
                 JOIN contabilidad_general.cuentas cc ON c.cuenta = cc.cuenta
        WHERE t.tipo_movimiento = ANY (v_movimientos)
          AND t.periodo BETWEEN p_periodo_ini AND p_periodo_fin
          AND (p_movimientos <> 'IMP' OR t.referencia LIKE '%Prv. EX%')
          AND LEFT(t.item, v_corte_item) = v_tipo_item;
END;
$function$
;


