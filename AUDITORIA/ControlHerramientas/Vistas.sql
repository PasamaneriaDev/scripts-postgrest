auditoria.detalle_inventario_herramienta

CREATE OR REPLACE VIEW auditoria.detalle_inventario_herramienta_order_view
AS
SELECT *
FROM auditoria.detalle_inventario_herramienta
ORDER BY descripcion, secuencia;