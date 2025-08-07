SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3',



SELECT *
FROM cuentas_cobrar.facturas_cabecera
WHERE creacion_fecha > '20250101'
  AND cliente = '000273'



WITH v_precios AS (SELECT pg.codigo,
                          pg.unidad_despacho || pg.unidad AS unidad_medida,
                          (CASE
                               WHEN FALSE
                                   THEN (CASE
                                             WHEN pg.unidad = 'MT' OR pg.unidad = 'YD' THEN
                                                 100
                                             ELSE pg.unidad_despacho END)
                               ELSE 1 END)                AS unidad_despacho,
                          pg.unidad,
                          pg.descripcion,
                          pg.x_default,
                          CASE
                              WHEN pg.x_default THEN SUBSTR(pg.codigo, 1, 7)
                              ELSE pg.codigo END          AS codigo_busqueda
                   FROM lista_materiales.precios_grupos pg
                   WHERE NOT pg.no_imprimir
                     AND pg.precio_base <> 0
                     AND pg.codigo BETWEEN '1' AND '2'),
     con_item AS (SELECT *
                  FROM (SELECT xi.item AS item, v.*
                        FROM v_precios v
                                 JOIN LATERAL (SELECT i.item
                                               FROM control_inventarios.items i
                                               WHERE i.item LIKE v.codigo_busqueda || '%'
                                                 AND TRIM(i.codigo_rotacion) IN
                                                     ('AA', 'XA', 'AC', 'MM', 'AP', 'PO', 'MA', 'AB', 'AS')
                                                 AND TRIM(i.codigo_rotacion) <> 'XX'
                                                 AND SUBSTRING(i.clase_producto FROM 2 FOR 1) <> 'Z'
                                                 AND SUBSTRING(i.descripcion FROM 1 FOR 2) <> 'A-'
                                                 AND i.es_vendible
                                               LIMIT 1) xi ON TRUE
                        WHERE LENGTH(v.codigo) > 8
                        UNION ALL
                        SELECT xi.item AS item, v.*
                        FROM v_precios v
                                 JOIN LATERAL (SELECT i.item
                                               FROM control_inventarios.items i
                                               WHERE i.item LIKE v.codigo_busqueda || '%'
                                                 AND SUBSTRING(i.item FROM 1 FOR 7) = SUBSTRING(v.codigo FROM 1 FOR 7)
                                                 AND (
                                                   SUBSTRING(i.item FROM 1 FOR LENGTH(v.codigo)) = v.codigo
                                                       OR
                                                   (SUBSTRING(i.item FROM 8 FOR 1) = '0' AND v.x_default)
                                                   )
                                                 AND NOT (SUBSTRING(i.item, 1, 1) = '5' AND SUBSTRING(i.item, 14, 1) = 'A')
                                                 AND NOT EXISTS(SELECT 1
                                                                FROM lista_materiales.precios_grupos pgex
                                                                WHERE pgex.codigo = i.item)
                                                 AND i.unidad_medida = v.unidad
                                                 AND TRIM(i.codigo_rotacion) IN
                                                     ('AA', 'XA', 'AC', 'MM', 'AP', 'PO', 'MA', 'AB', 'AS')
                                                 AND TRIM(i.codigo_rotacion) <> 'XX'
                                                 AND SUBSTRING(i.clase_producto FROM 2 FOR 1) <> 'Z'
                                                 AND SUBSTRING(i.descripcion FROM 1 FOR 2) <> 'A-'
                                                 AND i.es_vendible
                                               LIMIT 1) xi ON TRUE
                        WHERE LENGTH(v.codigo) <= 8) AS v1)