SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::text;


SELECT *
FROM control_inventarios.transacciones
WHERE transaccion = '  51722265';

SELECT *
FROM control_inventarios.distribucion
WHERE transaccion = '  51722266';

    SELECT i.bodega,
           i.costo_promedio,
           cl.valor_materia_prima
            ,
           cl.valor_mano_obra
            ,
           cl.valor_gastos_fabricacion
            ,
           (cl.valor_materia_prima + cl.valor_mano_obra + cl.valor_gastos_fabricacion) AS costo_unitario_total,
           cl.mantenimiento_materia_prima,
           cl.nivel_materia_prima,
           cl.acumulacion_materia_prima,
           cl.mantenimiento_mano_obra,
           cl.nivel_mano_obra,
           cl.acumulacion_mano_obra,
           cl.mantenimiento_gastos_fabricacion,
           cl.nivel_gastos_fabricacion,
           cl.acumulacion_gastos_fabricacion
    FROM control_inventarios.items i
             LEFT JOIN LATERAL (SELECT (c.mantenimiento_materia_prima + c.nivel_materia_prima +
                                        c.acumulacion_materia_prima)      AS valor_materia_prima,
                                       (c.mantenimiento_mano_obra + c.nivel_mano_obra +
                                        c.acumulacion_mano_obra)          AS valor_mano_obra,
                                       (c.mantenimiento_gastos_fabricacion + c.nivel_gastos_fabricacion +
                                        c.acumulacion_gastos_fabricacion) AS valor_gastos_fabricacion,
                                       *
                                FROM inventario_proceso.costos c
                                WHERE c.item = i.item
                                  AND c.tipo_costo = 'Standard') AS cl ON TRUE
    WHERE i.item = '4603300585923RP';

SELECT *
FROM control_inventarios.id_bodegas
WHERE bodega = 'GT7'

SELECT *
FROM inventario_proceso.costos c
WHERE c.tipo_costo = 'Standard'
  AND (COALESCE(c.mantenimiento_materia_prima + c.nivel_materia_prima +
                c.acumulacion_materia_prima, 0) <> 0 AND
       COALESCE(c.mantenimiento_mano_obra + c.nivel_mano_obra +
                c.acumulacion_mano_obra, 0) <> 0 AND
       COALESCE(c.mantenimiento_gastos_fabricacion + c.nivel_gastos_fabricacion +
                c.acumulacion_gastos_fabricacion, 0) <> 0)


select LEFT('asdf'::text, 1) = 'M'


SELECT
    sum(heap_blks_hit) / (sum(heap_blks_hit) + sum(heap_blks_read)) AS cache_hit_ratio
FROM pg_statio_user_tables;