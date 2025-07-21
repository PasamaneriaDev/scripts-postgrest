-- DROP FUNCTION auditoria.reporte_ventas_costo_mayor_precio(date, date);

CREATE OR REPLACE FUNCTION auditoria.reporte_ventas_costo_mayor_precio(fecha_inicial date, fecha_final date)
    RETURNS TABLE
            (
                referencia        character varying,
                fecha             date,
                cliente           character varying,
                item              character varying,
                codigo_rotacion   character varying,
                descripcion       character varying,
                cantidad          numeric,
                costo_venta       numeric,
                precio            numeric,
                codigo_precio     character varying,
                es_almacen_saldos text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        (SELECT fd.referencia,
                fd.fecha,
                fd.cliente,
                fd.item,
                fd.codigo_rotacion,
                fd.descripcion,
                fd.cantidad,
                (fd.costo * 1.34) AS costo_venta,
                fd.precio,
                fd.codigo_precio,
                CASE WHEN ib.es_almacen_saldos THEN 'SI' ELSE 'NO' END
         FROM cuentas_cobrar.facturas_detalle fd
                  JOIN control_inventarios.items i ON i.item = fd.item
                  JOIN control_inventarios.id_bodegas ib ON fd.bodega = ib.bodega
         WHERE fd.fecha BETWEEN fecha_inicial AND fecha_final
           AND LEFT(fd.item, 1) IN ('1', '2', '3', '4', '5', '6', '9', 'B')
           AND i.es_vendible
           AND (i.es_fabricado OR i.produccion_externa)
           AND fd.codigo_precio <> 'CST'
           AND i.es_stock
           AND (fd.costo * 1.34) > fd.precio
           AND COALESCE(fd.status, '') <> 'V'
           AND COALESCE(fd.tipo_documento, '') <> 'B')
        UNION ALL
        (SELECT fd.referencia,
                fd.fecha,
                fd.cliente,
                fd.item,
                fd.codigo_rotacion,
                fd.descripcion,
                fd.cantidad,
                (fd.costo * 1.34) AS costo_venta,
                fd.precio,
                fd.codigo_precio,
                CASE WHEN ib.es_almacen_saldos THEN 'SI' ELSE 'NO' END
         FROM puntos_venta.facturas_detalle fd
                  JOIN control_inventarios.items i ON i.item = fd.item
                  JOIN control_inventarios.id_bodegas ib ON fd.bodega = ib.bodega
         WHERE fd.fecha BETWEEN fecha_inicial AND fecha_final
           AND LEFT(fd.item, 1) IN ('1', '2', '3', '4', '5', '6', '9', 'B')
           AND i.es_vendible
           AND (i.es_fabricado OR i.produccion_externa)
           AND fd.codigo_precio <> 'CST'
           AND i.es_stock
           AND (fd.costo * 1.34) > fd.precio
           AND COALESCE(fd.status, '') <> 'V'
           AND COALESCE(fd.tipo_documento, '') <> 'B')
        ORDER BY item, fecha;
END;
$function$
;
