WITH existencias AS (SELECT b.bodega,
                            r0.descripcion,
                            CASE
                                WHEN LEFT(B.ITEM, 1) = '1' THEN 'Confecciones'
                                WHEN LEFT(B.ITEM, 1) = '2' THEN 'Telares'
                                WHEN LEFT(B.ITEM, 1) = '3' THEN 'Trenzadoras'
                                WHEN LEFT(B.ITEM, 1) = '4' THEN 'Tintoreria'
                                WHEN LEFT(B.ITEM, 1) = '5' THEN 'Calcetines'
                                WHEN LEFT(B.ITEM, 1) = '6' THEN 'Encajes'
                                WHEN LEFT(B.ITEM, 1) = 'B' THEN 'Hilos'
                                ELSE 'OTROS' END grupo,
                            r1.codigo_rotacion,
                            SUM(b.existencia)    total_existencia
                     FROM control_inventarios.bodegas b
                              INNER JOIN (SELECT ib.bodega bodega, ib.descripcion descripcion
                                          FROM control_inventarios.id_bodegas ib
                                          WHERE ib.es_punto_venta = TRUE) r0 ON r0.bodega = b.bodega
                              LEFT JOIN (SELECT i.item item, i.codigo_rotacion codigo_rotacion
                                         FROM control_inventarios.items i) r1
                                        ON r1.item = b.item
                     WHERE r1.codigo_rotacion IS NOT NULL
                       AND r1.codigo_rotacion != ''
                       AND b.bodega = ANY('{020,021,022,027}'::text[])
                     GROUP BY b.bodega, r0.descripcion, r1.codigo_rotacion, grupo
                     ORDER BY B.BODEGA ASC, grupo, r1.codigo_rotacion ASC)
SELECT bo.bodega, gp.grupo, cr.codigo, r1.total_existencia
FROM (SELECT UNNEST('{020,021,022,027}'::text[]) AS bodega) AS bo
         CROSS JOIN
     (SELECT UNNEST('{Confecciones,Telares,Trenzadoras,Tintoreria,Calcetines,Encajes,Hilos}'::text[]) AS grupo) AS gp
         CROSS JOIN (SELECT codigo
                     FROM lista_materiales.codigos_rotacion cr) AS cr
    left join existencias r1 on r1.bodega = bo.bodega and r1.grupo = gp.grupo and r1.codigo_rotacion = cr.codigo
where coalesce(r1.total_existencia, 0) <> 0
ORDER BY bo.bodega, gp.grupo, cr.codigo;


SELECT b.bodega,
       r0.descripcion,
       CASE
           WHEN LEFT(B.ITEM, 1) = '1' THEN 'Confecciones'
           WHEN LEFT(B.ITEM, 1) = '2' THEN 'Telares'
           WHEN LEFT(B.ITEM, 1) = '3' THEN 'Trenzadoras'
           WHEN LEFT(B.ITEM, 1) = '4' THEN 'Tintoreria'
           WHEN LEFT(B.ITEM, 1) = '5' THEN 'Calcetines'
           WHEN LEFT(B.ITEM, 1) = '6' THEN 'Encajes'
           WHEN LEFT(B.ITEM, 1) = 'B' THEN 'Hilos'
           ELSE 'OTROS' END grupo,
       r1.codigo_rotacion,
       SUM(b.existencia)    total_existencia
FROM control_inventarios.bodegas b
         INNER JOIN (SELECT ib.bodega bodega, ib.descripcion descripcion
                     FROM control_inventarios.id_bodegas ib
                     WHERE ib.es_punto_venta = TRUE) r0 ON r0.bodega = b.bodega
         LEFT JOIN (SELECT i.item item, i.codigo_rotacion codigo_rotacion FROM control_inventarios.items i) r1
                   ON r1.item = b.item
WHERE r1.codigo_rotacion IS NOT NULL
  AND r1.codigo_rotacion != ''
  AND b.bodega = '020'
GROUP BY b.bodega, r0.descripcion, r1.codigo_rotacion, grupo
ORDER BY B.BODEGA ASC, grupo, r1.codigo_rotacion ASC







CREATE INDEX idx_id_bodegas_bodega
ON control_inventarios.id_bodegas (bodega);
