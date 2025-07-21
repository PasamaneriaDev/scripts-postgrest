select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'


SELECT b.bodega, b.descripcion
FROM control_inventarios.id_bodegas b
WHERE b.es_punto_venta
  AND b.fecha_fin_transacciones IS NULL
  AND b.descripcion NOT ILIKE '%(Primera)%'
ORDER BY bodega


SELECT bodega, fecha_conteo, corte_conteo, fisico_conteo
FROM control_inventarios.bodegas
WHERE NOT auditoria_conteo
  AND fecha_conteo BETWEEN '2024-11-01' AND '2024-12-05'



SELECT bodega, fecha_conteo
FROM control_inventarios.bodegas
WHERE fecha_conteo BETWEEN '2024-11-01' AND '2024-12-05'
  AND conteo_grabado
ORDER BY fecha_conteo DESC;

IF
(SELECT i.es_almacen_saldos
 FROM control_inventarios.id_bodegas i
 WHERE i.bodega = '320')
THEN
WITH t
         AS
         (SELECT ('{' || bodega || ',' || bodega_primera || '}')::TEXT[] bodega
          FROM sistema.parametros_almacenes
          WHERE bodega_primera <> ''
            AND terminal = '01')
SELECT t.bodega
INTO _bodega
FROM t
WHERE ARRAY [p_bodega] <@ t.bodega;

END IF;

SELECT *
FROM control_inventarios.bodegas b
WHERE b.bodega = ANY ('{820}'::TEXT[])
  AND b.fecha_conteo = '2024-09-13'
  AND b.conteo_grabado



/******************************************************************/
/******************************************************************/

SELECT *
FROM (SELECT ib.bodega
      FROM control_inventarios.id_bodegas ib
      WHERE (ib.es_punto_venta
          AND ib.fecha_fin_transacciones IS NULL)
         OR ib.bodega = '040') idb
         INNER JOIN LATERAL
    (
    SELECT b.fecha_conteo
    FROM control_inventarios.bodegas b
    WHERE b.corte_conteo <> b.fisico_conteo
      AND b.fecha_conteo IS NOT NULL
      AND b.conteo_grabado
      AND NOT b.auditoria_conteo
      AND b.bodega = idb.bodega
    GROUP BY b.fecha_conteo
    ) t ON TRUE
where bodega = '820'
ORDER BY idb.bodega, t.fecha_conteo;



SELECT ib.bodega, b.fecha_conteo -- 16 512
FROM control_inventarios.id_bodegas ib
         JOIN control_inventarios.bodegas b ON ib.bodega = b.bodega
WHERE (ib.es_punto_venta OR ib.bodega = '040')
  AND b.corte_conteo <> b.fisico_conteo
  AND b.fecha_conteo IS NOT NULL
  AND b.conteo_grabado
  AND b.auditoria_conteo = FALSE
GROUP BY ib.bodega, b.fecha_conteo
ORDER BY ib.bodega, b.fecha_conteo;

/******************************************************************/
/******************************************************************/


[{"item":"1B4U3186606013M","descripcion":"PANTALON ALG\/POL BLANCO-2EST","sistema":"1.000","conteo":"1"}]


select * From control_inventarios.conteo_diferencia_imprimir_fnc(
         '820',
        '2024-09-16',
        '[{"item":"1B4U3186606013M","descripcion":"PANTALON ALG\/POL BLANCO-2EST","sistema":"1.000","conteo":"1"}]')