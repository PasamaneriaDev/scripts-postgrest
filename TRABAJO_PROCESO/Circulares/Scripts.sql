SELECT LEFT(RIGHT('0000020669027', 9), 8), RIGHT('0000020669027', 9), RIGHT('0000000' || '1231', 8)


SELECT *
FROM trabajo_proceso.orden_rollo_buscar_x_codigo_orden_codigo_barra('02064879001');

SELECT *
FROM trabajo_proceso.ordenes_rollos_detalle
ORDER BY codigo_orden; --fecha_registro

SELECT maquina, *
FROM trabajo_proceso.ordenes o
WHERE codigo_orden = '7M-02000029';

INSERT INTO trabajo_proceso.ordenes_rollos_detalle (codigo_orden, peso)
VALUES ('7M-02000029', 150.75),
       ('7M-02000029', 150.75),
       ('7M-02000029', 200.25);



SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3';

SELECT TRIM(SUBSTRING('00107177016' FROM 2 FOR 9)) || '-' || TRIM(SUBSTRING('00107177016' FROM 11 FOR 1))

SELECT *
FROM "public".isdigit('0010717701-6')


SELECT "right"('0000020669027', 3), LEFT('0000020669027', LENGTH('0000020669027') - 3) AS resultado;



SELECT *
FROM activos_fijos.activos

SELECT *
FROM trabajo_proceso.ordenes o
WHERE LEFT(o.codigo_orden, 2) = '7M'
  AND estado = 'Abierta';

/*
7M-02000076
7M-02000085
7M-02000088
7M-02000089
7M-02000094
7M-02000080

*/
SELECT *
FROM trabajo_proceso.ordenes o
WHERE codigo_orden IN (
                       '7M-02000039',
                       '7M-02000023',
                       '7M-02000041'
    )


SELECT *
FROM trabajo_proceso.ordenes_rollos_detalle
ORDER BY codigo_orden, numero_rollo; --fecha_registro

SELECT *
FROM trabajo_proceso.ordenes_rollos_defectos;

select



SELECT *
FROM control_inventarios.transacciones
WHERE creacion_fecha = CURRENT_DATE;

SELECT *
FROM trabajo_proceso.ordenes
where codigo_orden = '7M-02000076'
ORDER BY codigo_orden;
-

SELECT *
FROM sistema.interface
WHERE fecha::date = CURRENT_DATE



SELECT *
FROM trabajo_proceso.defectos_fabrica


SELECT *
FROM control_inventarios.ubicaciones
WHERE bodega = 'B7M';



INSERT INTO trabajo_proceso.ordenes_rollos_defectos (codigo_orden, numero_rollo,
                                                     defectos_fabrica_id, creacion_usuario, creacion_fecha)
VALUES ('7M-02000085', '002', 'H-01', '3191', '2025-06-24');
INSERT INTO trabajo_proceso.ordenes_rollos_defectos (codigo_orden, numero_rollo,
                                                     defectos_fabrica_id, creacion_usuario, creacion_fecha)
VALUES ('7M-02000085', '002', 'M-01', '3191', '2025-06-24');
INSERT INTO trabajo_proceso.ordenes_rollos_defectos (codigo_orden, numero_rollo,
                                                     defectos_fabrica_id, creacion_usuario, creacion_fecha)
VALUES ('7M-02000085', '002', 'M-06', '3191', '2025-06-24');
INSERT INTO trabajo_proceso.ordenes_rollos_defectos (codigo_orden, numero_rollo,
                                                     defectos_fabrica_id, creacion_usuario, creacion_fecha)
VALUES ('7M-02000085', '002', 'M-07', '3191', '2025-06-24');



SELECT *
FROM trabajo_proceso.ordenes o
where estado = 'Abierta'
    AND LEFT(codigo_orden, 2) = 'T7'


SELECT *
FROM trabajo_proceso.ordenes
WHERE codigo_orden IN (
                       '7M-02000088', '7M-02000085'
    )



SELECT o.codigo_orden,
       t.item,
       t.componente,
       t.cantidad_solicitada,
       SUM(t.cant_etreg)                                     AS cant_etreg,
       t.descrip_centcosto,
       t.nombre_user,
       t.es_tarjeta,
       ARRAY_TO_STRING(ARRAY_AGG(t.comentario), ',')         AS comentario,
       o.orden_complemento,
       o.codigo_coleccion,
       LPAD(o.secuencia_codigo_barra, 12, '0')               AS cod_bar,
       CASE WHEN o.ultimo_lote_malla THEN 'SI' ELSE 'NO' END AS ultimo_lote_malla,
       o.maquina
FROM "+vEgreso_automItm.LblTablaRepImprime.text+" t
         INNER JOIN trabajo_proceso.ordenes o ON t.codigo_orden = o.codigo_orden
WHERE LEFT(t.codigo_orden, 2) = 'T7'
   OR LEFT(t.codigo_orden, 2) = 'T9'
GROUP BY o.codigo_orden, t.item, t.componente, t.cantidad_solicitada, t.descrip_centcosto, t.nombre_user,
         t.es_tarjeta, o.orden_complemento, o.codigo_coleccion, o.ultimo_lote_malla
ORDER BY o.codigo_orden;


select LEFT('', LENGTH('') - 3),
           RIGHT('', 3)

select comentario, maquina, *
from trabajo_proceso.ordenes
where left(codigo_orden, 2) = '4H'
and length(comentario) > 50
