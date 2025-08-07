select *
from control_inventarios.transacciones t
join control_inventarios.id_bodegas ib on t.bodega = ib.bodega
where t.fecha > '2025-01-01'
and t.tipo_movimiento = 'TRANSFER+'
and ib.tiene_transito
and t.cantidad <> cantidad_recibida
-- and t.transaccion = ' 104048155'
--and bodega = '001'



select * --item, sum(cantidad)
from control_inventarios.transacciones t
where t.transaccion = ' 104092553'
-- and (cantidad = coalesce(cantidad_recibida, 0) and tipo_movimiento = 'TRANSFER+')
and (cantidad_recibida <> 0 or recepcion_completa);


select *
from sistema.bitacora
where usuario = '3191'
and fecha_inicial = current_date;

select *
from control_inventarios.transferencias_pendientes_resumen('100', '')
;

update control_inventarios.transacciones
set cantidad_recibida = 0,
    recepcion_completa = false
where transaccion = ' 104048155';


select * --item, sum(cantidad)
from control_inventarios.transacciones t
where t.transaccion = ' 104092553';

SELECT *
FROM control_inventarios.transferencia_errores
WHERE fecha_recepcion = CURRENT_DATE

select *
from control_inventarios.items



SELECT r1.*, LPAD(x.numero::text, 10, ' ') AS transaccion
    FROM (SELECT a.item
               , v.tipo
               , ROUND((CASE
                            WHEN a.cantidad_recibida > a.cantidad_enviada
                                THEN a.cantidad_enviada
                            ELSE a.cantidad_recibida END) * v.operador,
                       i.numero_decimales::integer)     AS cantidad
               , i.costo_promedio                       AS costo
               , v.ubicacion
               , 'REU-EXI / REUBICACION ' AS referencia
          FROM JSON_TO_RECORDset('[
              {
                "item": "7025026641209G",
                "cantidad_enviada": 100,
                "cantidad_recibida": 90,
                "item_nuevo": false,
                "ubicacion_ini": "UBIC001",
                "ubicacion_fin": "UBIC002"
              },
              {
                "item": "X31X10655606010",
                "cantidad_enviada": 50,
                "cantidad_recibida": 50,
                "item_nuevo": true,
                "ubicacion_ini": "UBIC003",
                "ubicacion_fin": "UBIC004"
              }
            ]') a (item text, cantidad_enviada numeric, cantidad_recibida numeric,
                                                 item_nuevo boolean, ubicacion_ini text, ubicacion_fin text)
                   JOIN control_inventarios.items i ON i.item = a.item
                   CROSS JOIN LATERAL ( VALUES ('REUB CANT-', -1, a.ubicacion_ini),
                                               ('REUB CANT+', 1, a.ubicacion_fin)) v (tipo, operador, ubicacion)
          WHERE a.cantidad_recibida > 0
            AND a.ubicacion_fin <> '') r1
             INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener( '001') x
                        ON TRUE

/*******************************************************************************************************************/
begin;
select *
FROM control_inventarios.recepcion_transferencia_reubicacion(' 104087060','[{"item":"1MV100L8717231","cantidad_enviada":1.0,"cantidad_recibida":1.0,"ubicacion_ini":"0000","ubicacion_fin":"","item_nuevo":false},{"item":"1MV10XL8940301","cantidad_enviada":1.0,"cantidad_recibida":1.0,"ubicacion_ini":"0000","ubicacion_fin":"","item_nuevo":false},{"item":"1MV12XL8415081","cantidad_enviada":1.0,"cantidad_recibida":3.0,"ubicacion_ini":"0000","ubicacion_fin":"","item_nuevo":false},{"item":"1UCW0366711341","cantidad_enviada":1.0,"cantidad_recibida":1.0,"ubicacion_ini":"0000","ubicacion_fin":"A000","item_nuevo":false},{"item":"17600026942051","cantidad_enviada":0.0,"cantidad_recibida":1.0,"ubicacion_ini":"0000","ubicacion_fin":"","item_nuevo":true}]', '3191');

rollback;

select *
from sistema.interface
where usuarios = '3191'
and modulo = 'DESPACHOS'
and fecha = current_date::text;

SELECT *
FROM control_inventarios.transacciones
WHERE transaccion = ' 104087060'
and tipo_movimiento = 'TRANSFER+';

SELECT *
FROM control_inventarios.transferencia_errores
WHERE transaccion = ' 104087060';


/*******************************************************************************************************************/
begin;
select *
FROM control_inventarios.recepcion_transferencia_reubicacion(' 104092933', true,'[{"item":"28280125942055","cantidad_enviada":50.0,"cantidad_recibida":1.0,"ubicacion_ini":"0000","ubicacion_fin":"A001","item_nuevo":false},{"item":"28280125939255","cantidad_enviada":150.0,"cantidad_recibida":150.0,"ubicacion_ini":"0000","ubicacion_fin":"A003","item_nuevo":false}]', '3191');

rollback;

commit;

select *
from sistema.interface
where usuarios = '3191'
and fecha = current_date::text;

SELECT transaccion, bodega, tipo_movimiento, fecha, cantidad,
       cantidad_recibida, recepcion_completa, ubicacion, item, referencia
FROM control_inventarios.transacciones
WHERE transaccion = ' 104092933'
and tipo_movimiento = 'TRANSFER+';

SELECT *
FROM control_inventarios.transferencia_errores
WHERE transaccion = ' 104092933';
--


    -- 104092933



select *
from sistema.usuarios_activos
--where usuario = '3191'
where ip_equipo_usuario is not null


