SELECT 'ALEX LOZA'            vendedor,
       'AL'                   codigo_vendedor,
       '2024'                 a1,
       '2025'                 a2,
       m.nombre               nombre_mayorista,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-1'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS enero1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-2'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS febrero1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-3'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS marzo1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-4'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS abril1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-5'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS mayo1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-6'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS junio1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-7'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS julio1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-8'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS agosto1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-9'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS septiembre1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-10'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS octubre1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-11'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS noviembre1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2024-12'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS diciembre1,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-1'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS enero2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-2'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS febrero2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-3'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS marzo2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-4'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS abril2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-5'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS mayo2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-6'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS junio2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-7'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS julio2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-8'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS agosto2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-9'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS septiembre2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-10'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS octubre2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-11'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS noviembre2,
       SUM(CASE
               WHEN CONCAT(EXTRACT(YEAR FROM c.fecha), '-', EXTRACT(MONTH FROM c.fecha)) = '2025-12'
                   THEN (c.monto_total - c.iva)
               ELSE 0 END) AS diciembre2
FROM cuentas_cobrar.facturas_cabecera c,
     cuentas_cobrar.clientes m
WHERE c.vendedor = 'AL'
  AND (EXTRACT(YEAR FROM c.fecha) = '2025' OR EXTRACT(YEAR FROM c.fecha) = '2024')
  AND m.codigo = c.cliente
  AND c.status IS NULL
  AND (c.tipo_documento IS NULL OR c.tipo_documento = 'C')
GROUP BY c.cliente, m.nombre
ORDER BY m.nombre ASC


-- puntos_venta.facturas_detalle_ventas source

CREATE OR REPLACE VIEW puntos_venta.facturas_detalle_ventas
AS
SELECT fd.referencia,
       fd.cliente,
       fd.item,
       fd.descripcion,
       fd.descuento,
       fd.iva,
       fd.costo,
       fd.precio,
       fd.ultimo_costo,
       fd.cantidad,
       fd.fecha,
       fd.periodo,
       fd.total_precio,
       fd.total_costo,
       fd.vendedor,
       fd.tiene_iva,
       fd.status,
       fd.tipo_documento,
       fd.codigo_venta,
       fd.codigo_inventario,
       fd.bodega,
       fd.ubicacion,
       fd.caja,
       fd.tipo_pago,
       fd.codigo_precio,
       fd.secuencia,
       fd.es_stock,
       fd.fecha_migrada,
       fd.modulo_postgres,
       fd.migracion,
       fd.codigo_rotacion,
       fd.cantidad_devuelta,
       fd.valor_descuento_adicional
FROM puntos_venta.facturas_detalle fd
         JOIN control_inventarios.items i ON fd.item::text = i.item::text
WHERE (COALESCE(fd.status, ''::character varying)::text <> 'ANULADA'::text AND
       (i.es_stock AND (i.es_fabricado OR i.produccion_externa) AND "left"(i.item::text, 1) <> '0'::text OR
        ("left"(fd.codigo_venta::text, 1) = ANY (ARRAY ['V'::text, 'D'::text, 'O'::text])) AND
        fd.codigo_inventario::text = 'PRT'::text) OR fd.item::text = 'SALDOS'::text)
  AND NOT (("left"(fd.item::text, 7) = 'ZVARIOS'::text OR "left"(fd.item::text, 2) = 'ZM'::text OR
            "left"(fd.item::text, 4) = 'Z900'::text OR fd.item::text = 'Z9020'::text OR
            "left"(fd.item::text, 4) = 'Z901'::text OR "left"(fd.item::text, 7) = 'ZDISENO'::text OR
            "left"(fd.item::text, 6) = 'ZTELAS'::text AND fd.item::text <> 'ZTELAS21'::text) AND
           (fd.bodega::text = '006'::text OR fd.bodega::text = 'C'::text OR fd.bodega::text = 'Z'::text OR
            fd.bodega::text = '122'::text))
  AND NOT (fd.item::text = 'ZTELAS17'::text AND fd.bodega::text = 'Z'::text)
  AND NOT ("left"(fd.item::text, 1) = 'H'::text AND fd.bodega::text = '129'::text);
