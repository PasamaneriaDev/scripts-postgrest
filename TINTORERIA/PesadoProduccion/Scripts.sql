SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3';


/******************************************************************************************/
-- TRABAJOS EN PROCESO MALLAS
/******************************************************************************************/
SELECT o.codigo_orden,
       o.item,
       o.cantidad_planificada,
       o.estado,
       o.fecha_inicio_planificacion,
       o.fecha_entrega_planificada,
       o.fecha_entrega_real,
       o.fecha_emision,
       o.estado,
       i.descripcion,
       i.unidad_medida,
       RIGHT(o.item, 1),
       i.bodega,
       i.ubicacion,
       i.seccion_destino
FROM trabajo_proceso.ordenes o
         INNER JOIN
     control_inventarios.items i ON o.item = i.item
WHERE LEFT(o.item, 1) = '7'
  AND RIGHT(o.item, 1) = 'F'
  AND o.estado <> 'Cerrada';



SELECT *
FROM control_inventarios.items
WHERE item = '7202G23010105A'


-- ITEMS DE LA BODEGA GT7
SELECT *
FROM control_inventarios.items
WHERE bodega = 'GT7'

-- ORDENES ITMES CON BODEGA GT7
SELECT o.codigo_orden,
       o.item,
       o.cantidad_planificada,
       o.estado,
       o.fecha_inicio_planificacion,
       o.fecha_entrega_planificada,
       o.fecha_entrega_real,
       o.fecha_emision,
       o.estado,
       i.descripcion,
       i.unidad_medida,
       RIGHT(o.item, 1),
       i.bodega,
       i.seccion_destino
FROM trabajo_proceso.ordenes o
         INNER JOIN
     control_inventarios.items i ON o.item = i.item
WHERE i.bodega = 'GT7'

/******************************************************************************************/
-- TRABAJOS EN PROCESO HILOS
/******************************************************************************************/
SELECT o.codigo_orden,
       o.item,
       o.cantidad_planificada,
       o.estado,
       o.fecha_inicio_planificacion,
       o.fecha_entrega_planificada,
       o.fecha_entrega_real,
       o.fecha_emision,
       o.estado,
       i.descripcion,
       i.unidad_medida,
       RIGHT(o.item, 1),
       i.bodega,
       i.ubicacion,
       i.seccion_destino
FROM trabajo_proceso.ordenes o
         INNER JOIN
     control_inventarios.items i ON o.item = i.item
WHERE LEFT(o.item, 1) = '4'
  AND RIGHT(o.item, 1) = 'R'
  AND o.estado <> 'Cerrada';



SELECT *
FROM control_inventarios.items
WHERE item = '7202G23010105A'


-- ITEMS DE LA BODEGA GT7
SELECT *
FROM control_inventarios.items
WHERE bodega = 'MT4'

-- ORDENES ITMES CON BODEGA GT7
SELECT o.codigo_orden,
       o.item,
       o.cantidad_planificada,
       o.estado,
       o.fecha_inicio_planificacion,
       o.fecha_entrega_planificada,
       o.fecha_entrega_real,
       o.fecha_emision,
       o.estado,
       i.descripcion,
       i.unidad_medida,
       RIGHT(o.item, 1),
       i.bodega,
       i.seccion_destino
FROM trabajo_proceso.ordenes o
         INNER JOIN
     control_inventarios.items i ON o.item = i.item
WHERE i.bodega = 'MT4'


SELECT peso_cono, ubicacion
FROM item_grabar


/***************/
-- PESOS CARROS
/***************/

SELECT *
FROM trabajo_proceso.peso_carro_carton_kilos($1)


SELECT *
FROM control_inventarios.id_bodegas


/******************************************/

SELECT o.codigo_orden,
       o.secuencia_codigo_barra,
       o.item,
       o.cantidad_planificada,
       o.cantidad_fabricada,
       o.estado,
       o.fecha_inicio_planificacion,
       o.fecha_entrega_planificada,
       o.fecha_entrega_real,
       o.fecha_emision,
       o.estado,
       i.descripcion,
       i.unidad_medida,
       RIGHT(o.item, 1),
       i.bodega,
       i.ubicacion,
       i.seccion_destino
FROM trabajo_proceso.ordenes o
         INNER JOIN
     control_inventarios.items i ON o.item = i.item
WHERE LEFT(o.codigo_orden, 2) IN ('T7')
  AND o.estado <> 'Cerrada';

-- T7-02002439G
-- T4-00028516 esta con bodega MG$


SELECT bodega
FROM control_inventarios.items
WHERE item = '4200403010105VS' sql_Tab_Transac =


SELECT codigo_empresa, descripcion, codigo
FROM activos_fijos.activos
WHERE LEFT(codigo, 1) <> 'C'
  AND codigo_empresa <> ''
  AND codigo_empresa =

SELECT *
FROM puntos_venta.reporte_reclamos(7)



SELECT item,
       tipo_costo,
       mantenimiento_materia_prima,
       mantenimiento_gastos_fabricacion,
       mantenimiento_mano_obra,
       nivel_materia_prima,
       nivel_mano_obra,
       nivel_gastos_fabricacion,
       acumulacion_gastos_fabricacion,
       acumulacion_mano_obra,
       acumulacion_materia_prima
FROM costos.costos
WHERE item = ''
  AND tipo_costo = 'Standard';


SELECT *
FROM costos.costos


SELECT *
FROM control_inventarios.transacciones



SELECT *
FROM control_inventarios.transacciones
WHERE maquina IS NULL



/* ORDEN CERRADA */
-- TB-00024682

SELECT *
FROM trabajo_proceso.resumen_produccion
ORDER BY ultima_actualizacion DESC


/*********************************/
-- MALLAS: T7-02001572G - 7206030660601F
SELECT *
FROM trabajo_proceso.ordenes
WHERE codigo_orden = 'T7-02002345G';


SELECT *
FROM control_inventarios.transacciones
WHERE item = '7206030660601F';

-- HILOS:  TB-00024683  - 440S200552217R

SELECT *
FROM trabajo_proceso.ordenes
WHERE codigo_orden = 'TB-00024683';

SELECT *
FROM control_inventarios.transacciones
WHERE item = '440S200552217R';


SELECT tcc.codigo_orden,
       o.item,
       i.descripcion,
       tcc.cantidad,
       o.cantidad_planificada,
       o.cantidad_fabricada,
       tcc.observaciones,
       tcc.estado_lote,
       tcc.tono,
       tcc.gramaje,
       tcc.ancho,
       tcc.encogimiento,
       tcc.solidez_humedo,
       tcc.solidez_frote,
       tcc.kilos_prueba,
       tcc.defectos_observados,
       tcc.creacion_usuario,
       tcc.creacion_fecha
FROM trabajo_proceso.tintoreria_control_calidad tcc
         JOIN trabajo_proceso.ordenes o ON tcc.codigo_orden = o.codigo_orden
         JOIN control_inventarios.items i ON o.item = i.item
--WHERE tcc.creacion_fecha BETWEEN '2022-01-01' AND '2022-01-31';


-- Gramaje no obligatori
-- aprobado sin observ

SELECT *
FROM trabajo_proceso.tintoreria_control_calidad



SELECT item, bodega, seccion_destino, ubicacion
FROM control_inventarios.items
WHERE COALESCE(ubicacion, '') <> ''


SELECT FORMAT('%s', '1', '1') AS hola;



SELECT CASE
           WHEN string_barras ~ '^(-)?[0-9]+$' = TRUE THEN
               CASE
                   WHEN LENGTH(string_barras) >= 12 THEN
                       CAST((LEFT(RIGHT('0000' || string_barras::NUMERIC, 5), 4)::NUMERIC / 100) AS character varying)
                   ELSE
                       CASE
                           WHEN (LEFT(string_barras, 6)) <> '000000' THEN
                               CASE
                                   WHEN string_barras::NUMERIC > 0 THEN
                                       string_barras
                                   ELSE
                                       '0'
                                   END
                           ELSE
                               string_barras
                           END
                   END
           ELSE
               string_barras
           END AS peso_kil


SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3'

SELECT (CURRENT_DATE - INTERVAL '7 days')::date AS fecha;


SELECT *
FROM trabajo_proceso.tintoreria_control_calidad;


SELECT o.*
FROM trabajo_proceso.ordenes o
         JOIN control_inventarios.items i ON i.item = o.item
WHERE o.codigo_orden = 'T7-02002401G'

/*****************************/

SELECT *
FROM trabajo_proceso.tintoreria_pesos_balanza;

SELECT *
FROM control_inventarios.transacciones
WHERE fecha = CURRENT_DATE;


SELECT seccion_destino
FROM control_inventarios.items
WHERE item = '7208030671723F';


SELECT *
FROM trabajo_proceso.registro_prod_web
WHERE codigo_orden = 'T7-02002439G';


SELECT *
FROM control_inventarios.distribucion
WHERE fecha = CURRENT_DATE control_inventarios.inventarios_reporte_analisis


SELECT ('now'::text)::date

SELECT *
FROM control_inventarios.inventarios_reporte_analisis('', TRUE);

BEGIN;
SELECT trabajo_proceso.tintoreria_control_calidad_merge(
               '{"codigo_orden":"T7-02002432","observaciones":"","estado_lote":"APROBADO","tono":"","gramaje":"","ancho":"32","encogimiento_ancho":"","encogimiento_largo":"","kilos_prueba":"","defectos_observados":"","solidez_humedo":"","solidez_frote":""}',
               '3191');

ROLLBACK;


SELECT *
FROM trabajo_proceso.tintoreria_control_calidad;

SELECT *
FROM trabajo_proceso.tintoreria_ordenes_enviadas;



SELECT *
FROM sistema.ip_almacen
WHERE ip LIKE '127%';


SELECT b.ciclo_conteo, b.fecha_conteo, b.*
FROM control_inventarios.bodegas b

SELECT primer_conteo, ultimo_conteo
FROM sistema.parametros_almacenes
WHERE bodega



SELECT transaccion,
       cantidad,
       bodega,
       ubicacion,
       cnt,
       bodega_final,
       ubicacion_final,
       tipo_movimiento,
       fecha,
       cantidad_recibida,
       fecha_recepcion,
       creacion_usuario,
       creacion_hora,
       referencia,
       documento,
       costo,
       cliente,
       periodo,
       nombre_cliente,
       nombre
FROM control_inventarios.item_consulta_kardex(
        '" + p_item + "', '" + p_fech_in + "', '" + p_fecha_fin + "', '{" + p_bodegas + "}'::VARCHAR[])
    +


-- DROP FUNCTION control_inventarios.items_kardex_valido(varchar, date, date, _varchar);

SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::text
and hora = '15:10:38'

INSERT INTO (item, loctid, tstore, ttranno, tdate, trantyp, ref, applid, tcost, sqty, per, adduser, adddate, addtime, secu_post) VALUES
([7217030625202F], [GT7], [GV03], [  51722235],         {^2025/05/01}, [LI], [De GV03 a G103], [TP], 14.19775, -0.32000, [202505], [3191], {^2025-05-01}, [14:45:03], [49362351])



select *
from trabajo_proceso.tintoreria_pesos_balanza