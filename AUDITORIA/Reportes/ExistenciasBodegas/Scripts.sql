/*
por bodega, ubicacion y consignacion
-- segun periodo cambia tabla
--
*/


select *
from sistema.usuarios_activos
where


select to_char( to_timestamp ( '15:24:00', 'HH24:MI:SS' ) , 'HH12:MI:SS' );

select to_char( to_timestamp ( current_time, 'HH24:MI:SS' ) , 'HH12:MI:SS' ) as hora;

SELECT TO_CHAR(CURRENT_TIME::time, 'HH24:MI:SS') AS hora_actual;

Select * From trabajo_proceso.ordenes_buscar_codigo_orden_codigo_barra()


, format('INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 (ttranno, loctid, item, ref, anio_trime, trantyp, tdate, sqty, tcost, applid, docno, tstore, price, adduser, adddate, addtime, per) VALUES ([%s], [%s], [%s], [%s], %s, [%s], {^%s}, %s, %s, [%s], [%s], [%s], %s, [%s], {^%s}, [%s], [%s])',
    s.transaccion,
    s.bodega,
    s.item,
    s.referencia,
    COALESCE(s.anio_trimestre::varchar, ''),
    CASE WHEN s.tipo_movimiento = 'AJUS CANT+' THEN 'AR' ELSE 'AI' END,
    TO_CHAR(s.fecha, 'YYYY-MM-DD'),
    s.cantidad::VARCHAR,
    s.costo::VARCHAR,
    s.modulo,
    s.documento,
    s.ubicacion,
    COALESCE(s.precio::VARCHAR, ''),
    s.creacion_usuario,
    TO_CHAR(s.fecha, 'YYYY-MM-DD'),
    ('now'::text)::time(0),
    TO_CHAR(CURRENT_DATE, 'YYYYMM')
)


select format('hola %s', 'mundo');