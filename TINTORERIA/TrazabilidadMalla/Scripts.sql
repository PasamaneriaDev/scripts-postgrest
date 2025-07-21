SELECT *
FROM trabajo_proceso.tintoreria_pesos_balanza
WHERE COALESCE(numero_rollo, '') <> '';

SELECT *
FROM trabajo_proceso.ordenes_rollos_detalle oc
WHERE oc.codigo_orden = '7M-02000088'

/*Sacamos todos los rollos pertenecientes a la orden de tintoreria, sin bodega(nos indica si fue eliminado manualmente)*/
SELECT tp.codigo_orden, tp.peso_neto, tp.creacion_fecha, tp.codigo_orden_crudo, tp.numero_rollo
FROM trabajo_proceso.tintoreria_pesos_balanza tp
WHERE tp.codigo_orden = 'T7-02003086'
  AND COALESCE(tp.bodega, '') <> '';

/*Sacamos los rollos crudos*/
SELECT oc.codigo_orden,
       oc.peso_crudo,
       oc.tonalidad,
       oc.creacion_fecha,
       tp.codigo_orden,
       oc.numero_rollo,
       o.maquina,
       oc.codigo_orden_hilo
FROM trabajo_proceso.tintoreria_pesos_balanza tp
         JOIN trabajo_proceso.ordenes_rollos_detalle oc
              ON tp.codigo_orden_crudo = oc.codigo_orden
                  AND tp.numero_rollo = oc.numero_rollo
         JOIN trabajo_proceso.ordenes o ON o.codigo_orden = oc.codigo_orden
WHERE tp.codigo_orden = 'T7-02003086'
  AND COALESCE(tp.bodega, '') <> '';

/*Sacamos los Paros del Crudo por Rollo*/
SELECT pr.motivo, pr.fecha_inicio, pr.fecha_fin, pr.maquina
FROM trabajo_proceso.ordenes_rollos_paros_mantenimiento pr
WHERE tipo = 'P'
  AND codigo_orden = '7M-02000088'
  AND numero_rollo = '001';

/*Sacamos los Defectos del Crudo*/
SELECT rd.defectos_fabrica_id, df.descripcion
FROM trabajo_proceso.ordenes_rollos_defectos rd
         JOIN trabajo_proceso.defectos_fabrica df ON rd.defectos_fabrica_id = df.defectos_fabrica_id
WHERE codigo_orden = '7M-02000088'
  AND numero_rollo = '001';

/*Sacamos la orden del hilo*/
SELECT o.codigo_orden, o.item, o.maquina, o.comentario, o.fecha_ultima_entrega
FROM trabajo_proceso.ordenes o
WHERE o.codigo_orden = '1C-F7384800091'


SELECT o.codigo_orden, o.item, o.maquina, o.comentario, o.fecha_ultima_entrega
FROM trabajo_proceso.ordenes_rollos_detalle oc
         JOIN trabajo_proceso.ordenes o ON o.codigo_orden = oc.codigo_orden_hilo
WHERE oc.codigo_orden = '7M-02000088'
  AND oc.numero_rollo = '001';


SELECT *
FROM trabajo_proceso.ordenes o
WHERE o.estado = 'Abierta'
  AND LEFT(o.codigo_orden, 2) = 'T7'


SELECT *
FROM trabajo_proceso.tintoreria_pesos_balanza
WHERE creacion_fecha > CURRENT_DATE - 6


SELECT rd.defectos_fabrica_id, df.descripcion
FROM trabajo_proceso.ordenes_rollos_defectos rd
         JOIN trabajo_proceso.defectos_fabrica df ON rd.defectos_fabrica_id = df.defectos_fabrica_id
WHERE codigo_orden = '7M-02000088'
  AND numero_rollo = '001';


SELECT *
FROM trabajo_proceso.tintoreria_pesos_balanza
WHERE numero_rollo <> ''

SELECT pb.codigo_orden
FROM trabajo_proceso.tintoreria_pesos_balanza pb
WHERE pb.codigo_orden_crudo = '7M-02000088'
  AND pb.numero_rollo = '001'
  AND COALESCE(pb.bodega, '') <> '';



select *
from control_inventarios.transacciones
where fecha = current_date
limit 10


