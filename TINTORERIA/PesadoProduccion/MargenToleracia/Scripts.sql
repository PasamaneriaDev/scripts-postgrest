SELECT e.componente
FROM trabajo_proceso.ordenes o
         JOIN lista_materiales.estructuras e ON e.item = o.item
    AND e.componente LIKE LEFT(o.item, 6) || '%'
WHERE o.codigo_orden = 'T7-02003135';

SELECT t.cantidad
FROM control_inventarios.transacciones t
WHERE t.tipo_movimiento = 'EGRE ORDE'
  AND t.item = '7201026010105A'
  AND t.referencia = 'T7-02003135';

SELECT *--SUM(tpb.peso_neto)
FROM trabajo_proceso.tintoreria_pesos_balanza tpb
WHERE tpb.bodega <> ''
  AND tpb.codigo_orden = 'T7-02003135';


