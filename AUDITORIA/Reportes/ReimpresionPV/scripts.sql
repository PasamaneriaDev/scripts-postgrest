SELECT *
FROM puntos_venta.facturas_cabecera fc
ORDER BY fecha DESC;

SELECT *
FROM puntos_venta.facturas_cabecera fc
WHERE tipo_documento = 'C'
ORDER BY fecha DESC;

037 - 101 - 000000634

SELECT *
FROM puntos_venta.reporte_factura('037101000000632', 'F')

SELECT CURRENT_DATE::text

SELECT *
FROM puntos_venta.vales
WHERE numero_vale = '12003995';

SELECT *
FROM puntos_venta.pagos
WHERE referencia = '1208942028';

SELECT *
FROM puntos_venta.reporte_vale('12003995');


SELECT 15.000::integer || '%'



SELECT *
FROM sistema.usuarios_activos
ORDER BY fecha DESC


SELECT * FROM auditoria.reporte_etiquetas_ubicaciones_doble('[{"bodega":"000","ubicacion":"0001"},{"bodega":"023","ubicacion":"0000"},{"bodega":"001","ubicacion":"0157"}]')


select *
from sistema.interface
where fecha = current_date::text


