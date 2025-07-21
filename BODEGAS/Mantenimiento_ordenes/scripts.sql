SELECT *
FROM trabajo_proceso.ordenes;



SELECT *
FROM trabajo_proceso.ordenes o
WHERE LEFT(o.codigo_orden, 2) = '7M'
  AND estado = 'Abierta';

SELECT *
FROM trabajo_proceso.ordenes o
WHERE orden_trazabilidad IS NOT NULL;


-- Activos

SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3'


SELECT codigo_orden, item, maquina
FROM trabajo_proceso.ordenes
WHERE LEFT(codigo_orden, 2) = '7M'
LIMIT 26



SELECT *
FROM (VALUES ('001'), ('002'), ('003'), ('004')) a (codigo_orden)
WHERE a.codigo_orden BETWEEN '002' AND '002'

SELECT 3 + 16 + 7 + 19 + 8 + 6 + 5 + 4 + 5 + 6 + 4 + 5 + 5 + 5


SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3'


SELECT t.centro_costo_origen,
       t.codigo_orden,
       t.item,
       t.cantidad_solicitada,
       t.nro_requerimiento,
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                                                                       (t.cantidad_solicitada),
                                                                                                       '0', ''), '1',
                                                                                               ''), '2', ''), '3', ''),
                                                                       '4', ''), '5', ''), '6', ''), '7', ''), '8', ''),
                               '9', ''), '.', ''), ' ', '') AS unidad_req,
       CASE
           WHEN REGEXP_REPLACE((t.cantidad_solicitada), '[^.0-9]', '', 'g') = ''
               THEN '0'
           ELSE REGEXP_REPLACE((t.cantidad_solicitada), '[^.0-9]', '', 'g')
           END                                              AS cant_solic,
       t.comentario,
       t.operador_bodeguero,
       t.no_entregado,
       t.centro_costo_destino,
       t.urgente,
       i.descripcion,
       c.descripcion                                        AS desc_cecost_ori
FROM trabajo_proceso.requerimiento_guia t
         INNER JOIN control_inventarios.items i ON TRIM(t.item) = i.item
         INNER JOIN activos_fijos.centros_costos c ON t.centro_costo_origen = c.codigo
WHERE t.tipo_requerimiento = 'EGR'
  AND (t.centro_costo_destino = 'S15')
  AND t.codigo_orden <> ''
  AND t.fecha_requerimiento <= CURRENT_DATE
GROUP BY t.centro_costo_origen, t.codigo_orden, t.item, t.cantidad_solicitada, t.nro_requerimiento, t.comentario,
         t.operador_bodeguero, t.no_entregado,
         t.centro_costo_destino, t.urgente, i.descripcion, c.descripcion
ORDER BY t.centro_costo_origen, t.item;


SELECT t.centro_costo_origen,
       t.codigo_orden,
       t.item,
       t.cantidad_solicitada,
       t.nro_requerimiento,
       REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                                                               REPLACE(
                                                                       REPLACE(
                                                                               REPLACE(
                                                                                       REPLACE(REPLACE((t.cantidad_solicitada), '0', ''), '1', ''),
                                                                                       '2',
                                                                                       ''),
                                                                               '3',
                                                                               ''),
                                                                       '4',
                                                                       ''),
                                                               '5',
                                                               ''),
                                                       '6', ''),
                                               '7', ''), '8', ''),
                               '9', ''), '.', ''), ' ',
               '')                                                              AS unidad_req,
       CASE
           WHEN REGEXP_REPLACE((t.cantidad_solicitada), '[^.0-9]', '', 'g') = ''
               THEN '0'
           ELSE REGEXP_REPLACE((t.cantidad_solicitada), '[^.0-9]', '', 'g') END AS cant_solic,
       t.comentario,
       t.operador_bodeguero,
       t.no_entregado,
       t.centro_costo_destino,
       t.urgente,
       i.descripcion,
       c.descripcion                                                            AS desc_cecost_ori
FROM trabajo_proceso.requerimiento_guia t
         INNER JOIN control_inventarios.items i ON TRIM(t.item) = i.item
         INNER JOIN activos_fijos.centros_costos c ON t.centro_costo_origen = c.codigo
WHERE t.tipo_requerimiento = 'EGR'
  AND (t.centro_costo_destino SIMILAR TO ('V08|V46|S15'))
  AND t.codigo_orden <> ''
  AND t.fecha_requerimiento <= '2025-06-13'
  AND (operador_bodeguero ISNULL OR operador_bodeguero = '')
GROUP BY t.centro_costo_origen, t.codigo_orden, t.item,
         t.cantidad_solicitada, t.nro_requerimiento, t.comentario,
         t.operador_bodeguero, t.no_entregado,
         t.centro_costo_destino, t.urgente, i.descripcion,
         c.descripcion
ORDER BY t.centro_costo_origen, t.item;


SELECT *
FROM trabajo_proceso.requerimiento_guia t
WHERE fecha_solicitud > '2024-01-01'
  AND LEFT(codigo_orden, 2) = '4T'
  AND (t.centro_costo_destino SIMILAR TO ('V08|V46|S15'))
  AND (operador_bodeguero ISNULL OR operador_bodeguero = '');

SELECT entrega_total, cantidad_necesaria,  *
FROM trabajo_proceso.requerimientos
WHERE codigo_orden = '4T-00009806'
  AND componente = '440S200575937R'



select *
from control_inventarios.ubicaciones
where item = '440S200575937R'


select *
from sistema.interface
where fecha is not null
order by fecha desc


select current_date


INSERT INTO f:\home\spp\trabproc\data\ordenes (  item, codorden, seccodbar, cantplanif, fecentplan, fecemision,   feciniplan, prioridad, estado, comentario, problemas, manual,   bandrequer, bandhojaru, codcolecci, ultlotmall, secuprogra, maquina) VALUES ([7229030010105A], [7M-02000101], [], 5.500, {^2025-06-20}, {^2025-06-20}, {^2025-06-20}, [Normal], [Abierta], [], [], .T., .F., .F., [],.F.,0,[70-034])