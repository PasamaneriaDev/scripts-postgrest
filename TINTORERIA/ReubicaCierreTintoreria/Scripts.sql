BEGIN;



ROLLBACK;


SELECT *
FROM control_inventarios.ajustes
WHERE documento = '2019071250'

SELECT TO_CHAR(CURRENT_DATE, 'YYYYMM')


SELECT 'lleno' <> 'vacio' OR 'lleno' <> 'lleno'


SELECT *, bodega_reposicion
FROM cuentas_cobrar.clientes
WHERE cliente_consignacion;

SELECT codigo_orden,
       item,
       descripcion,
       bodega,
       ubicacion,
       cantidad_recibida,
       cerrado,
       reubicado,
       unidad_medida,
       cantidad_planificada,
       cantidad_fabricada
FROM trabajo_proceso.tintoreria_ordenes_x_recibir_bodega('T7-02002345G') rollback;

SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::varchar
  AND usuarios = '3191'
;

EXPLAIN ANALYZE
SELECT *
FROM control_inventarios.transacciones
WHERE fecha = CURRENT_DATE


SELECT *
FROM trabajo_proceso.ordenes
WHERE codigo_orden = 'T7-02002345G'


SELECT *
FROM trabajo_proceso.requerimientos
WHERE codigo_orden = 'T7-02002345G'

DROP VIEW control_inventarios.ubicaciones_actuales_reubicacion_manual_view;
CREATE VIEW control_inventarios.ubicaciones_actuales_reubicacion_manual_view AS
SELECT ubicacion, bodega, item
FROM control_inventarios.ubicaciones
WHERE existencia > 0
  AND (bodega != 'GT7' OR (bodega = 'GT7' AND ubicacion != 'GV03'));

SELECT *
FROM control_inventarios.items
WHERE LEFT(item, 4) = '1760';


SELECT *
FROM cheques.bancos;


SELECT *
FROM sistema.ip_almacen;


SELECT *
FROM sistema.parametros_almacenes
WHERE bodega = '622'


SELECT transaccionid
FROM cuentas_cobrar.pagos_tarjeta
WHERE comprobante = '030101000049328'


SELECT *
FROM public.latacungaauxpagos

SELECT *
FROM puntos_venta.pagos p
WHERE fecha_pago > CURRENT_DATE - 30
  AND tipo_pago = 'CHEQUE'


SELECT *
FROM cheques.cheques
WHERE creacion_fecha = CURRENT_DATE

SELECT *
FROM public.latacungaAuxDetalle INSERT INTO PUBLIC.latacungaAuxDetalle (banco, banconombre, cuenta, cheque,  cedula_ruc, nombre, valor, fecha_ingreso,  fecha_deposito, status )
VALUES ('02012195', 'FOMENTO', ' 000000000120', '0000620', '0107177016', 'GUACHICHULLCA CAJAMARCA JUAN IGNACIO', '4.14', '2025-05-05', '2025-05-05', '')