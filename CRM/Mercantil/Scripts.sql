SELECT v.bodega
     , a.item
     , v.tipo
     , 'TRN-MER/VENTA REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
     , a.fecha
     , v.cantidad                                                 AS cantidad
     , i.costo_promedio                                           AS costo
     , '0000'                                                     AS ubicacion
     , TO_CHAR(CURRENT_DATE, 'YYYYMM')                            AS periodo
     , LPAD(x.numero::text, 10, ' ')                              AS transaccion
FROM mercantil_tosi.ventas_pasa_diario a
         CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad * -1, '040'),
                                     ('TRANSFER+', a.cantidad, 'C40')) v (tipo, cantidad, bodega)
         JOIN control_inventarios.items i ON i.item = a.item
         CROSS JOIN LATERAL sistema.transaccion_inventario_numero_obtener('001') x
WHERE NOT a.procesado
  AND a.cantidad > 0
UNION ALL
SELECT v.bodega
     , a.item
     , v.tipo
     , 'TRN-MER/DEVOLUCION REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
     , a.fecha
     , v.cantidad                                                      AS cantidad
     , i.costo_promedio                                                AS costo
     , '0000'                                                          AS ubicacion
     , TO_CHAR(CURRENT_DATE, 'YYYYMM')                                 AS periodo
     , LPAD(x.numero::text, 10, ' ')                                   AS transaccion
FROM mercantil_tosi.ventas_pasa_diario a
         CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad, 'C40'),
                                     ('TRANSFER+', a.cantidad * -1, '040')) v (tipo, cantidad, bodega)
         JOIN control_inventarios.items i ON i.item = a.item
         CROSS JOIN LATERAL sistema.transaccion_inventario_numero_obtener('001') x
WHERE NOT a.procesado
  AND a.cantidad < 0;

drop table if exists ajuste_tmp;
CREATE TEMP TABLE ajuste_tmp AS
    SELECT *
    FROM (WITH fechas_unicas AS (SELECT DISTINCT a.fecha, 'VENTA' AS tipo_operacion
                                 FROM mercantil_tosi.ventas_pasa_diario a
                                 WHERE NOT a.procesado
                                   AND a.cantidad > 0
                                 UNION
                                 SELECT DISTINCT a.fecha, 'DEVOLUCION' AS tipo_operacion
                                 FROM mercantil_tosi.ventas_pasa_diario a
                                 WHERE NOT a.procesado
                                   AND a.cantidad < 0),
               numeros_transaccion AS (SELECT fecha,
                                              tipo_operacion,
                                              sistema.transaccion_inventario_numero_obtener('001') AS numero
                                       FROM fechas_unicas)
          SELECT v.bodega
               , a.item
               , v.tipo
               , 'TRN-MER/VENTA REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
               , a.fecha
               , v.cantidad                                                 AS cantidad
               , i.costo_promedio                                           AS costo
               , '0000'                                                     AS ubicacion
               , TO_CHAR(CURRENT_DATE, 'YYYYMM')                            AS periodo
               , LPAD(nt.numero::text, 10, ' ')                             AS transaccion
               , nt.tipo_operacion
          FROM mercantil_tosi.ventas_pasa_diario a
                   CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad * -1, '040'),
                                               ('TRANSFER+', a.cantidad, 'C40')) v (tipo, cantidad, bodega)
                   JOIN control_inventarios.items i ON i.item = a.item
                   JOIN numeros_transaccion nt ON a.fecha = nt.fecha AND nt.tipo_operacion = 'VENTA'
          WHERE NOT a.procesado
            AND a.cantidad > 0
          UNION ALL
          SELECT v.bodega
               , a.item
               , v.tipo
               , 'TRN-MER/DEVOLUCION REPORTADA ME' || TO_CHAR(a.fecha, 'DDMMYY') AS referencia
               , a.fecha
               , v.cantidad                                                      AS cantidad
               , i.costo_promedio                                                AS costo
               , '0000'                                                          AS ubicacion
               , TO_CHAR(CURRENT_DATE, 'YYYYMM')                                 AS periodo
               , LPAD(nt.numero::text, 10, ' ')                                  AS transaccion
               , nt.tipo_operacion
          FROM mercantil_tosi.ventas_pasa_diario a
                   CROSS JOIN LATERAL ( VALUES ('TRANSFER-', a.cantidad, 'C40'),
                                               ('TRANSFER+', a.cantidad * -1, '040')) v (tipo, cantidad, bodega)
                   JOIN control_inventarios.items i ON i.item = a.item
                   JOIN numeros_transaccion nt ON a.fecha = nt.fecha AND nt.tipo_operacion = 'DEVOLUCION'
          WHERE NOT a.procesado
            AND a.cantidad < 0) AS rf;

SELECT
    CASE
        WHEN ventas IS NOT NULL AND devoluciones IS NOT NULL THEN
            'Venta: ' || ventas || ' - Devolucion: ' || devoluciones
        WHEN ventas IS NOT NULL THEN
            'Venta: ' || ventas
        WHEN devoluciones IS NOT NULL THEN
            'Devolucion: ' || devoluciones
        ELSE
            'No hay transacciones'
    END AS resultado
FROM (
    SELECT
        STRING_AGG(DISTINCT CASE WHEN tipo_operacion = 'VENTA' THEN TRIM(transaccion) END, ',') AS ventas,
        STRING_AGG(DISTINCT CASE WHEN tipo_operacion = 'DEVOLUCION' THEN TRIM(transaccion) END, ',') AS devoluciones
    FROM ajuste_tmp
) t;

SELECT *
FROM mercantil_tosi.ventas_pasa_diario a
where fecha = '2025-06-15'
WHERE NOT a.procesado
  AND a.cantidad > 0


UPDATE mercantil_tosi.ventas_pasa_diario a
SET procesado = TRUE
WHERE NOT a.procesado
  AND a.cantidad > 0
  AND fecha < '2025-06-16'


SELECT *
FROM mercantil_tosi.ventas_pasa_diario vpd
         LEFT JOIN control_inventarios.items i ON vpd.item = i.item
WHERE NOT procesado
ORDER BY vpd.fecha, vpd.secuencial;

SELECT *
FROM mercantil_tosi.ventas_pasa_diario vpd
WHERE NOT procesado
ORDER BY vpd.fecha, vpd.secuencial;

UPDATE mercantil_tosi.ventas_pasa_diario a
SET procesado = FALSE
WHERE secuencial IN (489213, 489425,
                     489260,
                     489362,
                     489364,
                     489366,
                     489368,
                     489399,
                     489430,
                     489432,
                     489434,
                     489441,
                     489443,
                     489445,
                     489458,
                     489459,
                     489463,
                     489464,
                     489465,
                     489466,
                     489467,
                     489468,
                     489469,
                     489470,
                     489471,
                     489472,
                     489473,
                     489474,
                     489475,
                     489476,
                     489477,
                     489478,
                     489479,
                     489480,
                     489481,
                     489482,
                     489483,
                     489484,
                     489485,
                     489486,
                     489487,
                     489488,
                     489489,
                     489490,
                     489491,
                     489492,
                     489493,
                     489494,
                     489495,
                     489496,
                     489497,
                     489498,
                     489499,
                     489500,
                     489501,
                     489502,
                     489503,
                     489504,
                     489505,
                     489506,
                     489507,
                     489508,
                     489509,
                     489510,
                     489511,
                     489512,
                     489513,
                     489514,
                     489515,
                     489516,
                     489517,
                     489518,
                     489519,
                     489520,
                     489521,
                     489522,
                     489523,
                     489524,
                     489525,
                     489526,
                     489527,
                     489528,
                     489529,
                     489530,
                     489531,
                     489532,
                     489533,
                     489534,
                     489535,
                     489536,
                     489537,
                     489538,
                     489539,
                     489540,
                     489541,
                     489542,
                     489543,
                     489544,
                     489545,
                     489546,
                     489547,
                     489548,
                     489549,
                     489550,
                     489551,
                     489552
    );


SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::varchar
  AND usuarios = '3191'
  AND proceso = 'INSERT1'
ORDER BY secuencia

SELECT *
FROM control_inventarios.transacciones
WHERE creacion_fecha = CURRENT_DATE
  AND creacion_usuario = '3191'
  AND transaccion IN ('  51794911', '  51794910')
ORDER BY secuencia

/************************************************************************************************/
/************************************************************************************************/
/************************************************************************************************/
SELECT (CURRENT_DATE - (EXTRACT(DOW FROM CURRENT_DATE) || ' days')::interval)::date AS domingo_reciente;

SELECT pvs.item,
       i.descripcion,
       pvs.fecha,
       pvs.qty,
       pvs.extcost,
       pvs.costo_pasa,
       pvs.semana,
       pvs.comprobante
FROM mercantil_tosi.ventas_pasa_semanal pvs
         LEFT JOIN control_inventarios.items i ON pvs.item = i.item
WHERE NOT pvs.procesado
ORDER BY pvs.fecha, pvs.secuencial;

SELECT *
FROM mercantil_tosi.ventas_pasa_semanal vpd


SELECT COUNT(DISTINCT DATE_TRUNC('week', TO_DATE(pvs.fecha, 'DD/MM/YYYY'))) AS semanas
FROM mercantil_tosi.ventas_pasa_semanal pvs;


SELECT DATE_TRUNC('week', TO_DATE(pvs.fecha, 'DD/MM/YYYY'))::date                             AS fecha_inicio,
       (DATE_TRUNC('week', TO_DATE(pvs.fecha, 'DD/MM/YYYY'))::date + INTERVAL '6 days')::date AS fecha_fin,
       COUNT(*)                                                                               AS total_registros
FROM mercantil_tosi.ventas_pasa_semanal pvs
WHERE NOT pvs.procesado
GROUP BY DATE_TRUNC('week', TO_DATE(pvs.fecha, 'DD/MM/YYYY'))::date
ORDER BY fecha_inicio;


SELECT fecha, TO_DATE(pvs.fecha, 'DD/MM/YYYY')
FROM mercantil_tosi.ventas_pasa_semanal pvs
WHERE NOT pvs.procesado
GROUP BY fecha, TO_DATE(pvs.fecha, 'DD/MM/YYYY')

SELECT *
FROM mercantil_tosi.ventas_pasa_semanal pvs
WHERE NOT pvs.procesado
  AND fecha = '11/08/2022'


SELECT vps.item,
       vps.per,
       vps.qty,
       vps.extcost,
       vps.costo_pasa,
       p.precio,
       vps.fecha,
       (vps.qty * p.precio) AS total_precio
FROM mercantil_tosi.ventas_pasa_semanal vps
         LEFT JOIN control_inventarios.precios p ON vps.item = p.item AND p.tipo = 'MER'
WHERE TO_DATE(vps.fecha, 'DD/MM/YYYY') BETWEEN '2025-06-09' AND '2025-06-15'
  AND NOT procesado
ORDER BY TO_DATE(vps.fecha, 'DD/MM/YYYY')

SELECT *
FROM mercantil_tosi.ventas_pasa_semanal vps
WHERE TO_DATE(vps.fecha, 'DD/MM/YYYY') BETWEEN '2025-06-09' AND '2025-06-15'
  AND NOT procesado
ORDER BY qty;


SELECT SUM(CASE WHEN qty > 0 THEN 1 ELSE 0 END), SUM(CASE WHEN qty < 0 THEN 1 ELSE 0 END)
FROM mercantil_tosi.ventas_pasa_semanal vps
WHERE TO_DATE(vps.fecha, 'DD/MM/YYYY') BETWEEN '2025-06-09' AND '2025-06-15'
  AND NOT procesado;

UPDATE mercantil_tosi.ventas_pasa_semanal vps
SET procesado = FALSE
WHERE secuencial IN (243765, 243764,
                     243763,
                     243762,
                     243761,
                     243760,
                     243759,
                     243758,
                     243757,
                     243756,
                     243755,
                     243754,
                     243753,
                     243752,
                     243751,
                     243750,
                     243749,
                     243748,
                     243747,
                     243746,
                     243745,
                     243744,
                     243743,
                     243742,
                     243741,
                     243740,
                     243739,
                     243738,
                     243737,
                     243736,
                     243735,
                     243734,
                     243733,
                     243732,
                     243731,
                     243730,
                     243729,
                     243728,
                     243727,
                     243726,
                     243725,
                     243723,
                     243722,
                     243721,
                     243720,
                     243719,
                     243718,
                     243717,
                     243716,
                     243715,
                     243714,
                     243713,
                     243712,
                     243711,
                     243710,
                     243709,
                     243708,
                     243707,
                     243706,
                     243705,
                     243704,
                     243703,
                     243702,
                     243701,
                     243700,
                     243699,
                     243698,
                     243697,
                     243696,
                     243695,
                     243694,
                     243693,
                     243692,
                     243691,
                     243690,
                     243689,
                     243688,
                     243687,
                     243686,
                     243685,
                     243684,
                     243683,
                     243682,
                     243681,
                     243680,
                     243679,
                     243678,
                     243677,
                     243676,
                     243675,
                     243674,
                     243673,
                     243672,
                     243671,
                     243670,
                     243669,
                     243668,
                     243667,
                     243666,
                     243665,
                     243664,
                     243663,
                     243662,
                     243661,
                     243660,
                     243659,
                     243658,
                     243657,
                     243656,
                     243655,
                     243654,
                     243653,
                     243652,
                     243651,
                     243650,
                     243649,
                     243648,
                     243647,
                     243646,
                     243645,
                     243644,
                     243643,
                     243642,
                     243641,
                     243640,
                     243639,
                     243638,
                     243637,
                     243636,
                     243635,
                     243634,
                     243633,
                     243632,
                     243631,
                     243630,
                     243629,
                     243628,
                     243627,
                     243626,
                     243625,
                     243624,
                     243623,
                     243622,
                     243621,
                     243620,
                     243619,
                     243618,
                     243617,
                     243616,
                     243615,
                     243614,
                     243613,
                     243612,
                     243611,
                     243610,
                     243609,
                     243608,
                     243607,
                     243606,
                     243605,
                     243604,
                     243603,
                     243602,
                     243601,
                     243600,
                     243599,
                     243598,
                     243597,
                     243596,
                     243595,
                     243594,
                     243593,
                     243592,
                     243591,
                     243590,
                     243589,
                     243588,
                     243587,
                     243586,
                     243585,
                     243584,
                     243583,
                     243582,
                     243581,
                     243580,
                     243579,
                     243578,
                     243577,
                     243576,
                     243575,
                     243574,
                     243573,
                     243572,
                     243571,
                     243570,
                     243569,
                     243568,
                     243567,
                     243566,
                     243565,
                     243564,
                     243563,
                     243562,
                     243561,
                     243560,
                     243559,
                     243558,
                     243557,
                     243556,
                     243555,
                     243554,
                     243553,
                     243552,
                     243551,
                     243550,
                     243549,
                     243548,
                     243547,
                     243546,
                     243545,
                     243544,
                     243543,
                     243542,
                     243541,
                     243540,
                     243539,
                     243538,
                     243537,
                     243536,
                     243535,
                     243534,
                     243533,
                     243532,
                     243531,
                     243530,
                     243529,
                     243528,
                     243527,
                     243526,
                     243525,
                     243524,
                     243523,
                     243522,
                     243521,
                     243520,
                     243519,
                     243518,
                     243517,
                     243516,
                     243515,
                     243514,
                     243513,
                     243512,
                     243511,
                     243510,
                     243509,
                     243508,
                     243507,
                     243506,
                     243505,
                     243504,
                     243503,
                     243502,
                     243501,
                     243500,
                     243499,
                     243498,
                     243497,
                     243496,
                     243495,
                     243494,
                     243493,
                     243492,
                     243491,
                     243490,
                     243489,
                     243488,
                     243487,
                     243486,
                     243485,
                     243484,
                     243483,
                     243482,
                     243481,
                     243480,
                     243479,
                     243478,
                     243477,
                     243476,
                     243475,
                     243474,
                     243473,
                     243472,
                     243471,
                     243470,
                     243469,
                     243468,
                     243467,
                     243466,
                     243465,
                     243464,
                     243463,
                     243462,
                     243461,
                     243460,
                     243459,
                     243458,
                     243457,
                     243456,
                     243455,
                     243454,
                     243453,
                     243452,
                     243451,
                     243450,
                     243449,
                     243448,
                     243447,
                     243446,
                     243445,
                     243444,
                     243443,
                     243442,
                     243441,
                     243440,
                     243439,
                     243438,
                     243437,
                     243436,
                     243435,
                     243434,
                     243433,
                     243432,
                     243431,
                     243430,
                     243429,
                     243428,
                     243427,
                     243426,
                     243425,
                     243424,
                     243423,
                     243422,
                     243421,
                     243420,
                     243419,
                     243418,
                     243417,
                     243416,
                     243415,
                     243414,
                     243413,
                     243412,
                     243411,
                     243410,
                     243409,
                     243408,
                     243407,
                     243406,
                     243405,
                     243404,
                     243403,
                     243402,
                     243401,
                     243400,
                     243399,
                     243398,
                     243397,
                     243396,
                     243395,
                     243394,
                     243393,
                     243392,
                     243391,
                     243390,
                     243389,
                     243388,
                     243387,
                     243386,
                     243385,
                     243384,
                     243383,
                     243382,
                     243381,
                     243380,
                     243379,
                     243378,
                     243377,
                     243376,
                     243375,
                     243374,
                     243373,
                     243372,
                     243371,
                     243370,
                     243369,
                     243368,
                     243367,
                     243366,
                     243365,
                     243364,
                     243363,
                     243362,
                     243361,
                     243360,
                     243359,
                     243358,
                     243357,
                     243356,
                     243355,
                     243354,
                     243353,
                     243352,
                     243351,
                     243350,
                     243349,
                     243348,
                     243347,
                     243346,
                     243345,
                     243344,
                     243343,
                     243342,
                     243341,
                     243340,
                     243339,
                     243338,
                     243337,
                     243336,
                     243335,
                     243334,
                     243333,
                     243332,
                     243331,
                     243330,
                     243329,
                     243328,
                     243327,
                     243326,
                     243325,
                     243324,
                     243323,
                     243322,
                     243321,
                     243320,
                     243319,
                     243318,
                     243317,
                     243316,
                     243315,
                     243314,
                     243313,
                     243312,
                     243311,
                     243310,
                     243309,
                     243308,
                     243307,
                     243306,
                     243305,
                     243304,
                     243303,
                     243302,
                     243301,
                     243300,
                     243299,
                     243298,
                     243297,
                     243296,
                     243295,
                     243294,
                     243293,
                     243292,
                     243291,
                     243290,
                     243289,
                     243288,
                     243287,
                     243286,
                     243285,
                     243284,
                     243283,
                     243282,
                     243281,
                     243280,
                     243279,
                     243278,
                     243277,
                     243276,
                     243275,
                     243274,
                     243273,
                     243272,
                     243271,
                     243270,
                     243269,
                     243268,
                     243267,
                     243266,
                     243265
    )
;

SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido IN ('4059558', '4059559');

SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE numero_pedido IN ('4059558', '4059559')
ORDER BY numero_pedido;


BEGIN;
SELECT *
FROM mercantil_tosi.procesar_ventas_semanales('2025-06-09', '2025-06-15', '001', '3192');

SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido = ANY ('{4059560,4059561}');

SELECT *
FROM ordenes_venta.pedidos_detalle
WHERE numero_pedido = ANY ('{4059560,4059561}')
ORDER BY numero_pedido, cantidad_pendiente;

SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::varchar
  AND usuarios = '3192'
  AND proceso = 'INSERT1';

ROLLBACK;



SELECT pvs.item, i.descripcion, pvs.fecha, pvs.qty AS cantidad, p.precio, (pvs.qty * p.precio) AS total_precio
FROM mercantil_tosi.ventas_pasa_semanal pvs
         LEFT JOIN control_inventarios.items i ON pvs.item = i.item
         LEFT JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = 'MER'
WHERE NOT pvs.procesado
  AND TO_DATE(pvs.fecha, 'DD/MM/YYYY') BETWEEN $1 AND $2
ORDER BY pvs.fecha, pvs.secuencial;


select *
from control_inventarios.transacciones
where transaccion in (
    '  51795262'  ,'  51795263'  ,'  51795264'  ,'  51795266'
    )
order by secuencia