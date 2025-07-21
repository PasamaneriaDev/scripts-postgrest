SELECT ot.fecha,
       ot.tipo_gasto,
       tg.descripcion AS descripcion_gasto,
       ot.codigo_maquina,
       af.descripcion AS descripcion_maquina,
       ot.trabajo_requerido,
       ot.codigo_seccion_destino,
       ot.descripcion_seccion_destino,
       ot.codigo_seccion_cliente,
       ot.descripcion_seccion_cliente,
       ot.trabajo_realizado,
       ot.tipo_orden,
       ot.orden_terminada,
       ot.estado
FROM activos_fijos.ordenes_trabajo_cabecera ot
         LEFT JOIN activos_fijos.activos af ON ot.codigo_maquina = af.codigo_empresa
         LEFT JOIN activos_fijos.tipos_gastos tg ON ot.tipo_gasto = tg.codigo
WHERE ot.codigo_orden_trabajo = '0087616';


SELECT codigo_empresa, descripcion
FROM activos_fijos.activos
WHERE activos_fijos.activos.codigo_empresa = '40-069'

SELECT codigo, descripcion
FROM activos_fijos.tipos_gastos
WHERE activos_fijos.tipos_gastos.codigo = '1129'



SELECT a.recurso, a.tipo, a.total
FROM (SELECT 'MATERIALES'                        AS recurso,
             LEFT(maquinaria_item_trabajador, 1) AS tipo,
             SUM(unidad_horas * precio_unitario)    total
      FROM activos_fijos.ordenes_trabajo_detalle
      WHERE tipo_recurso = 'MAT'
        AND codigo_orden_trabajo = '0087616'
      GROUP BY LEFT(maquinaria_item_trabajador, 1)
      UNION ALL
      SELECT 'MANO DE OBRA' AS recurso, '' AS tipo, SUM(unidad_horas * costo_valor_hora) total
      FROM activos_fijos.ordenes_trabajo_detalle
      WHERE tipo_recurso = 'MOB'
        AND codigo_orden_trabajo = '0087616'
      UNION ALL
      SELECT 'MAQUINARIA' AS recurso, '' AS tipo, SUM(unidad_horas * costo_valor_hora) total
      FROM activos_fijos.ordenes_trabajo_detalle
      WHERE tipo_recurso = 'MAQ'
        AND codigo_orden_trabajo = '0068018') AS A


