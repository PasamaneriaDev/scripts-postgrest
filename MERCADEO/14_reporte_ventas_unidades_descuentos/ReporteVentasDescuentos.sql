-- DROP FUNCTION puntos_venta.reporte_ventas_ps_my_descuentos(varchar, varchar);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_ps_my_descuentos(periodo_inicial character varying, periodo_final character varying)
    RETURNS TABLE
            (
                modulo                text,
                referencia            character varying,
                fecha                 date,
                cliente               character varying,
                item                  character varying,
                descripcion           character varying,
                codigo_rotacion       character varying,
                periodo               character varying,
                PORCENTAJE_DSCTO      numeric,
                VALOR_DSCTO_ADICIONAL numeric,
                precio                numeric,
                cantidad              numeric,
                total_precio          numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        WITH cte AS (SELECT 'PS'                         AS MODULO,
                            fd.referencia,
                            fd.fecha,
                            fd.cliente,
                            fd.item,
                            fd.descripcion,
                            fd.codigo_rotacion,
                            fd.periodo,
                            fd.descuento,
                            fd.valor_descuento_adicional AS descuento_adic,
                            fd.precio,
                            fd.cantidad,
                            fd.total_precio
                     FROM puntos_venta.facturas_detalle fd
                              LEFT JOIN control_inventarios.items i ON fd.item = i.item
                     WHERE LEFT(fd.item, 1) IN ('1', '5')
                       AND i.unidad_medida IN ('UN', 'PQ')
                       AND fd.periodo BETWEEN periodo_inicial AND periodo_final
                     -- AND fd.total_precio > 0
                     UNION ALL
                     SELECT 'AR'                AS MODULO,
                            fd.referencia,
                            fd.fecha,
                            fd.cliente,
                            fd.item,
                            fd.descripcion,
                            fd.codigo_rotacion,
                            fd.periodo,
                            fd.descuento,
                            fd.descuento_etatex AS descuento_adic,
                            fd.precio,
                            fd.cantidad,
                            fd.total_precio
                     FROM cuentas_cobrar.facturas_detalle fd
                              LEFT JOIN control_inventarios.items i ON fd.item = i.item
                     WHERE LEFT(fd.item, 1) IN ('1', '5')
                       AND i.unidad_medida IN ('UN', 'PQ')
                       AND fd.periodo BETWEEN periodo_inicial AND periodo_final
            -- AND fd.total_precio > 0
        )

        SELECT cte.MODULO,
               cte.referencia,
               cte.fecha,
               cte.cliente,
               cte.item,
               REPLACE(REPLACE(cte.descripcion, ',', ''), ';', '')::varchar AS descripcion,
               cte.codigo_rotacion,
               cte.periodo,
               cte.descuento,
               cte.descuento_adic,
               cte.precio,
               cte.cantidad,
               cte.total_precio
        FROM cte
        ORDER BY cte.periodo, cte.item;
END;
$function$
;
