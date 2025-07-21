SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA5'
/**************************************************/
select *
 from ordenes_venta.pedidos_cabecera pc
order by pc.fecha_pedido desc

select pc.numero_pedido, pc.cliente, c.nombre,
       pc.fecha_pedido, pc.monto_iva, pc.monto_pendiente, pc.monto_despachado,
       pc.tipo_precio, pc.tipo_descuento_promocion, pc.creacion_fecha
from ordenes_venta.pedidos_cabecera pc
join cuentas_cobrar.clientes c on pc.cliente = c.codigo
order by pc.numero_pedido desc
limit 100;

select *
from ordenes_venta.pedidos_detalle pd



select *
    from ordenes_venta.vendedores


select descripcion, codigo_rotacion
from control_inventarios.items
where item = '111'

select *
from
ordenes_venta.recalcula_cabecera_pedido()



select *
 from ordenes_venta.pedidos_cabecera pc
where numero_pedido = '4053221';

select sum(subtotal)
 from ordenes_venta.pedidos_detalle pc
where numero_pedido = '4053221';


    select COALESCE(iva,0)/100 from cuentas_cobrar.clientes where codigo='007452';

select 396.17 * 1.15;



SELECT i.descripcion, i.codigo_rotacion, precio
FROM control_inventarios.items i
         JOIN control_inventarios.precios p ON p.item = i.item
  WHERE i.item = $1
    AND p.tipo_precio = $2





/******************************************************/


select *
from sistema.parametros
where modulo_id='SISTEMA';



select vendedor,*
from ordenes_venta.pedidos_cabecera
where LEFT(cliente,3) not similar to '999|991'
  AND COALESCE(estado,'')=''
  and COALESCE(tipo_pedido,'')<>'B';     --Los clientes que empiezan con 999,991 con pedidos internos. El tipo_pedido=’B’ son proformas.



select *
from ordenes_venta.pedidos_detalle

where numero_pedido='4055394'
where
LEFT(cliente,3) not similar to '999|991'
AND COALESCE(estado,'')=''
and COALESCE(tipo_pedido,'')<>'B'
and cantidad_pendiente>0;



select coalesce(left(tipo_comision, 1), '')
from ordenes_venta.vendedores;



INSERT INTO sistema.parametros (modulo_id, codigo, descripcion, alfa, numero, fecha, conversion_dolar,
                                fecha_ultima_actualizacion, fecha_migrada, migracion, numero_ord_mp, interface_envia)
VALUES ('SISTEMA', 'CORREO_AUTO_CAMBIO_PEDIDO', 'Correo al que se envia automaticamente cuando se hacen cambios en los pedidos de Mayorista', 'eduardo.cobo@pasa.ec', 0, null, FALSE,
        current_date, NULL, 'NO', NULL, FALSE);


select *
from sistema.parametros
where modulo_id='SISTEMA'
    and codigo='CORREO_AUTO_CAMBIO_PEDIDO';


SELECT *
from sistema.parametros_almacenes
where bodega = '001'


select *
from control_inventarios.id_bodegas
where bodega = '001';



select *
from ordenes_venta.pedidos_detalle_bitacora

select *
from sistema.email_masivo_cabecera
order by fecha desc



SELECT pc.numero_pedido,
       pc.cliente,
       c.nombre  AS nombre_cliente,
       pc.fecha_pedido,
       pc.monto_iva,
       pc.monto_pendiente,
       pc.monto_despachado,
       pc.tipo_precio,
       pc.tipo_descuento_promocion,
       v.nombres AS agente
FROM ordenes_venta.pedidos_cabecera pc
         JOIN cuentas_cobrar.clientes c ON pc.cliente = c.codigo
         JOIN ordenes_venta.vendedores v ON pc.vendedor = v.codigo
WHERE
   COALESCE(pc.estado, '') = ''
  AND LEFT(pc.cliente, 3) NOT SIMILAR TO '999|991'
  AND COALESCE(pc.tipo_pedido, '') <> 'B'
  AND COALESCE(LEFT(v.tipo_comision, 1), '') = 'C'
ORDER BY pc.fecha_pedido DESC



select *
from sistema.email_masivo_cabecera
order by fecha desc;

select *
from sistema.email_masivo_detalle
where numero_email = 2434

select upper(null)



  SELECT pc.numero_pedido, pc.cliente, c.nombre as nombre_cliente,
    pc.fecha_pedido, pc.monto_iva, pc.monto_pendiente, pc.monto_despachado,
    pc.tipo_precio, pc.tipo_descuento_promocion, v.nombres as agente
  FROM ordenes_venta.pedidos_cabecera pc
  JOIN cuentas_cobrar.clientes c on pc.cliente = c.codigo
  JOIN ordenes_venta.vendedores v on pc.vendedor = v.codigo
  WHERE -- (pc.numero_pedido = $1 or $1 = '' )
--     AND pc.fecha_pedido BETWEEN  $2 AND $3
     COALESCE(pc.estado,'')=''
    AND LEFT(pc.cliente,3) not similar to '999|991'
    AND COALESCE(pc.tipo_pedido,'')<>'B'
    AND (coalesce(left(v.tipo_comision, 1), '') = 'C' or true)
  ORDER BY pc.numero_pedido desc;

select 130 + 346



select *
from cuentas_cobrar.clientes
where codigo='001536';


select *
from sistema.interface
where fecha is not null
order by fecha desc


select *
    from ordenes_venta.pedidos_detalle_bitacora



INSERT INTO sistema.interface (sql)
VALUES ('UPDATE v:\sbtpro\SODATA\Sotran01 set extprice = 4.01,   ' ||
        'descrip = [CAMISETA M/C ALG/POL JASP.BCO LLANA],   disc = 50.000,   price = 8.03000,   macode = N ' ||
        'Where sono = [   4053461]   ' ||
        'And item = [176100M0007021]   ' ||
        'And secu_post = 1541426   ' ||
        'And custno = [006610]   ' ||
        'And cat_ruccli = []   ' ||
        'And disc = 100.000   ' ||
        'And cat_color = [0] ');

INSERT INTO sistema.interface (sql)
VALUES ('REPLACE tax WITH 221.47, ordamt WITH + 1697.91');





/***********************************/


select *
from ordenes_venta.pedidos_cabecera pc
where numero_pedido =    '4054935'
order by pc.fecha_pedido desc;

select *
from ordenes_venta.pedidos_detalle
where numero_pedido =    '4054935'





UPDATE v:\sbtpro\SODATA\Sotran01 set extprice = 7.79,   descrip = [CAMISETA POLO BASICA  M/C CUE ALG/POL BLANCO PIQUETETO],   disc = 21.000,   price = 9.86000,   macode = [N] Where sono = [   4054935]   And item = [17830046606011]   And descrip = [CAMISETA POLO BASICA  M/C CUE ALG/POL BLANCO PIQUETE]   And disc = 21.000

 SELECT *
 FROM control_inventarios.id_bodegas ib
 WHERE ib.centro_costo = 'V05'




 select *
 from ordenes_venta.pedidos_detalle_bitacora


















-- dias plazo en la cabecera

    -- Menu emergente en la tabla
-- Actualizar Dias Plazo


 --1--Actualizar días plazo en pedidos según cliente

select codigo,nombre,terminos_pago,dias_plazo
from cuentas_cobrar.clientes
where codigo = '003834';

SELECT numero_pedido, terminos_pago, dias_plazo, cliente
FROM ordenes_venta.pedidos_cabecera
WHERE numero_pedido = '4054927';

UPDATE ordenes_venta.pedidos_cabecera pc
SET terminos_pago = c.terminos_pago,
    dias_plazo = c.dias_plazo
FROM cuentas_cobrar.clientes c
WHERE pc.cliente = c.codigo
and numero_pedido = '4054927';

--2-- Modificar vendedor en pedido
-- Cuando se modifica el vendedor, los campos que apuntan el pedido a la ciudad tambien cambian...
-- Si se puede usera vendedores de otras ciudades para pedidos de otras ciudades
--CUENCA

UPDATE ordenes_venta.pedidos_cabecera

SET vendedor='AJ',
    codigo_venta='VFC', -- Para la cuenta contable de la facturacion
    bodega='001' --CUENCA

WHERE numero_pedido = '101030029';

UPDATE ordenes_venta.pedidos_detalle
SET vendedor='AJ',
    codigo_venta='VFC',
    bodega='001' --CUENCA
where numero_pedido='101030029';



--QUITO

UPDATE ordenes_venta.pedidos_cabecera
SET vendedor='KR',
    codigo_venta='VFQ',
    bodega='101' --QUITO
WHERE numero_pedido = '101030029';



UPDATE ordenes_venta.pedidos_detalle
SET vendedor='AJ',
    codigo_venta='VFC',
    bodega='001' --CUENCA
WHERE numero_pedido = '101030029';



--



--3 Modificar cliente en pedido

-- Modificar para agregar la interfaz
SELECT *
FROM ordenes_venta.pedidos_cambio_cliente_fnc('579076', '007892')



SELECT pc.numero_pedido, pc.dias_plazo, c.codigo, c.nombre, c.terminos_pago, c.dias_plazo, v.codigo, v.nombres
FROM ordenes_venta.pedidos_cabecera pc
         JOIN cuentas_cobrar.clientes c
              ON pc.cliente = c.codigo
         JOIN ordenes_venta.vendedores v ON pc.vendedor = v.codigo


order by fecha_pedido desc





select dias_plazo, terminos_pago
from ordenes_venta.pedidos_cabecera


















SELECT
  pc.numero_pedido, pc.dias_plazo as dias_plazo_pedido,
  c.codigo, c.nombre,
  c.terminos_pago, c.dias_plazo as dias_plazo_cliente
FROM ordenes_venta.pedidos_cabecera pc
JOIN cuentas_cobrar.clientes c
  ON pc.cliente = c.codigo
WHERE pc.numero_pedido = '4054927'



select *
from sistema.interface
order by secuencia desc



SELECT *
FROM pg_catalog.pg_stat_activity
WHERE query LIKE '%cuentas_cobrar.clientes%';


SELECT proname, prosrc, proargnames
FROM pg_proc
WHERE prosrc LIKE '%set pedidos%';



select *
from ordenes_venta.item_disponible_despachar_pedido()=




select *, left(tipo_comision, 1)
from ordenes_venta.vendedores


select iva, count(iva)
from cuentas_cobrar.clientes
group by iva





































select *, iva
from cuentas_cobrar.clientes
where iva = 0
--where codigo='000926';



SELECT terminos_pago, dias_plazo, COALESCE(iva, 0) / 100
FROM cuentas_cobrar.clientes
WHERE codigo = '000926';



select *-- sum(monto_pendiente)
from ordenes_venta.pedidos_cabecera
where cliente = '006620'
and monto_pendiente > 0

    select *
    from sistema.interface
    where secuencia > 812836446
    order by secuencia desc

select *
from ordenes_venta.orden_despacho
order by creacion_fecha desc;

select *
from ordenes_venta.despachos_pedidos
order by fecha desc;


select *
from ordenes_venta.pedidos_detalle_bitacora


select *
from cuentas_cobrar.clientes
where codigo = '007708'


select *
from ordenes_venta.pedidos_cabecera_bitacora