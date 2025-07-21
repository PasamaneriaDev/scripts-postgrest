select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'


SELECT * -- min(fecha_solicitud) AS fecha_minima
FROM trabajo_proceso.requerimiento_guia
WHERE centro_costo_origen = 'V33'
  AND ((fecha_entregada IS NOT NULL AND fecha_recibido_almacen IS NULL) OR
       (fecha_solicitud IS NOT NULL AND fecha_entregada IS NULL AND fecha_recibido_almacen IS NULL)
           AND fecha_solicitud > '2024-11-01'

  SELECT nro_requerimiento, centro_costo, nombre_centro_costo, item, descripcion, fecha_solicitud, fecha_requerimiento, " + _
  "  cantidad_solicitada, comentario, cantidad_entragada, fecha_entregada, fecha_recibido_almacen, estado " + _
  "FROM puntos_venta.requerimientos_consulta($1,$2,$3,$4,$5)

SELECT min(fecha_solicitud) as fecha
FROM puntos_venta.requerimientos_consulta('V33', '', '', '', '')
WHERE estado IN ('EN TRAMITE', 'ENTREGADO')



SELECT r.ruta, r.operacion, r.centro, r.proceso, hr.tiempo, hr.fecha_inicial, hr.fecha_final
FROM rutas.rutas r
         JOIN control_inventarios.items i
              ON i.ruta = r.ruta
         LEFT JOIN trabajo_proceso.hoja_ruta hr
                   ON hr.centro = r.centro AND hr.operacion = r.operacion AND hr.codigo_orden = '1C-F6066301422' AND
                      hr.centro = '188' AND hr.operacion = '0019'
WHERE i.item = '12470046606013';


SELECT r.ruta,
       r.operacion,
       r.centro,
       r.proceso,
       hr.tiempo,
       hr.fecha_inicial,
       hr.fecha_final,
       hr.fecha_inicial::date AS fecha,
       hr.fecha_inicial::time AS hora
FROM rutas.rutas r
         JOIN control_inventarios.items i
              ON i.ruta = r.ruta
         LEFT JOIN trabajo_proceso.hoja_ruta hr
                   ON hr.centro = r.centro AND hr.operacion = r.operacion AND hr.codigo_orden = '1C-F6066301422' AND
                      hr.centro = '188' AND hr.operacion = '0019'
WHERE i.item = '12470046606013';


select 16 + 10 + 7 + 16 + 10 + 10 + 10 + 10 + 10


