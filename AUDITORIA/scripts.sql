select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'

SELECT *
FROM control_inventarios.transacciones
WHERE tipo_movimiento = 'AJUS COST+'
  AND fecha > '2024-01-01'

SELECT *
FROM control_inventarios.ajustes
WHERE tipo = 'C'
and fecha > '20230101'

SELECT *
FROM control_inventarios.transacciones
WHERE documento = '0703202724'

SELECT *
FROM control_inventarios.distribucion
WHERE transaccion = ' 103623134'

SELECT *
FROM control_inventarios.transacciones_tipo_prb

SELECT *
FROM control_inventarios.transaccion_distribucion_tipo


SELECT table_name
FROM information_schema.tables
WHERE table_name LIKE '%transacc%';


INSERT INTO control_inventarios.ajustes (documento, item, costo, costo_nuevo, cantidad_ajuste, bodega, ubicacion, tipo,
                                         cuenta_ajuste, cuenta, anio_trimestre, creacion_fecha, creacion_hora,
                                         creacion_usuario)
VALUES ('2201202501', '16780XS6940301', 3.97965, 3.97965, -1.000, '122', '0000', 'A', '51105000000000000',
        '11304010200000000', 0, '2025-01-22', '08:57:09', '3028')



SELECT *
FROM sistema.interface
WHERE SQL LIKE '%ajustes%'

SELECT MIN(fecha), MAX(fecha)
FROM sistema.interface


/**/
SELECT *
FROM control_inventarios.ajustes
WHERE COALESCE(status, '') <> ''

SELECT *
FROM control_inventarios.ajustes aj
         INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener(CASE WHEN aj.secuencia >= 0 THEN '001' END) x
                    ON TRUE
WHERE aj.documento = '0703202724'
    51653681
UPDATE sistema.parametros_almacenes
SET numero_transaccion = numero_transaccion + 1
WHERE bodega = p_bodega
  AND terminal = '01'
RETURNING numero_transaccion::INTEGER
INTO w_numero;

51653681
SELECT numero_transaccion
FROM sistema.parametros_almacenes
WHERE bodega = '001'
  AND terminal = '01'


SELECT *
FROM control_inventarios.precios
WHERE item = 'C063'
  AND tipo = 'PVP'



SELECT r1.*, p.precio
FROM ((SELECT a.bodega
            , a.item
            , 'AJUS COST-'           AS        tipo
            , 'Cant. entregada en Cambio Cost' referencia
            , a.fecha
            , a.cantidad_ajuste * -1 AS        cantidad
            , a.costo
            , a.documento
            , a.ubicacion
            , a.cuenta_ajuste
            , a.cuenta
            , a.secuencia
       FROM control_inventarios.ajustes a
       WHERE a.documento = 'asdf')
      UNION ALL
      (SELECT a.bodega
            , a.item
            , 'AJUS COST+'      AS            tipo
            , 'Cant. recibida en Cambio Cost' referencia
            , a.fecha
            , a.cantidad_ajuste AS            cantidad
            , a.costo_nuevo     AS            costo
            , a.documento
            , a.ubicacion
            , a.cuenta_ajuste
            , a.cuenta
            , a.secuencia
       FROM control_inventarios.ajustes a
       WHERE a.documento = 'nuevo')
      ORDER BY secuencia, cantidad) r1
         LEFT JOIN control_inventarios.precios p ON p.item = r1.item AND p.tipo = 'PVP'


select *
from control_inventarios.items
    where existencia > 100;

/************************************************************************************/
/************************************************************************************/
/************************************************************************************/
/************************************************************************************/
/************************************************************************************/
/************************************************************************************/
/************************************************************************************/


-- BEGIN;
-- SELECT *
-- FROM control_inventarios.ajuste_costo_grabar_fnc(
--              '[{"item":"175500L6606011","costo":"1.65295","costo_nuevo":"1.7","cantidad_ajuste":"0.000","cuenta":"11204020202000000","cuenta_ajuste":"11101030104000000","tipo":"C","documento":"nuevo","referencia":""}]',
--              TRUE,
--              '3191');
--
-- rollback;

-- Ajuste New
SELECT *
FROM control_inventarios.ajustes
-- where creacion_fecha = current_date
WHERE documento = '0000007777';

--Transacciones New
SELECT *
FROM control_inventarios.transacciones
WHERE documento = '0000000123';

-- Distribucion new
SELECT *
FROM control_inventarios.distribucion d
WHERE exists(SELECT 1
FROM control_inventarios.transacciones a
WHERE a.documento = '0000000123'
    AND a.transaccion = d.transaccion
      )
;


/***/
/***/
select max(secuencia)
from sistema.interface
where fecha = current_date::varchar;

select *
from sistema.interface
where secuencia > 812857304
order by secuencia;

control_inventarios.ajuste_cantidad_grabar_fnc







SELECT b.existencia, item
FROM control_inventarios.bodegas b
WHERE b.bodega = 'MD'
AND item = 'M7212-BB'



SELECT b.existencia, b.item
FROM control_inventarios.bodegas b
join control_inventarios.items i on b.item = i.item
WHERE b.bodega = 'MD' and i.numero_decimales > 0;




control_inventarios.ajuste_cantidad_grabar_fnc



  Select (
  Select string_agg(DISTINCT documento, chr(13) ORDER BY(documento)) As documento
  From control_inventarios.ajustes
  where tipo = 'A'
  And status = ''
  And creacion_fecha <> CURRENT_DATE
  ) As ajuste_inventario
  , (
  Select string_agg(DISTINCT documento, chr(13) ORDER BY(documento)) As documento
  From control_inventarios.ajustes
  where tipo = 'C'
  And status = ''
  And creacion_fecha <> CURRENT_DATE
  ) As ajuste_costo;


select *
  From control_inventarios.ajustes
  where tipo = 'A'
  And status = ''
  And creacion_fecha <> CURRENT_DATE



update control_inventarios.ajustes
set status = 'C'
where ajustes.creacion_fecha <> current_date


{"item":"10170006243051","anio_trimestre":"0","cantidad_ajuste":"1.000","ubicacion":"0000","cuenta":"11101030601000000"}

select *
    from control_inventarios.ajuste_cantidad_actualizacion_inventario('0000000555', 'A', '', '3191')





Select a.documento, a.creacion_fecha, a.fecha, a.bodega, a.ubicacion
			 , a.item, i.descripcion as item_descripcion, a.anio_trimestre, a.costo, a.costo_nuevo
			 , concat(a.documento, a.tipo, left(a.item, 1)) as grupo
			 , case WHEN a.tipo = 'C'
							then a.cantidad_ajuste
							else case when a.status = 'C'
												then u.existencia
												else u.existencia - a.cantidad_ajuste
									 end
				 end As cantidad_anterior
			 , case WHEN a.tipo = 'C'
							then a.cantidad_ajuste
							else case when a.status = 'C'
												then u.existencia - a.cantidad_ajuste
												else u.existencia
									 end
				 end As cantidad_nueva
			 , CASE a.tipo
							when 'C' then 'CAMBIO DE COSTO'
							when 'A' then 'AJUSTE DE INVENTARIO'
							when 'T' then 'TOMA DE INVENTARIO'
							ELSE ''
				 END AS documento_descripcion
	 from control_inventarios.ajustes  a INNER JOIN
				 control_inventarios.items i On a.item = i.item left Join
				 control_inventarios.ubicaciones u ON (a.bodega, a.ubicacion, a.item) = (u.bodega, u.ubicacion, u.item)
		 where a.documento = '0000000123'
	ORDER BY grupo;



select *
from control_inventarios.items
where left(item, 1) = 'C'
limit 10

select *
from control_inventarios.inventarios_reporte_analisis('021')



select *
from control_inventarios.ajustes
where documento = '0020250101'




select *
from control_inventarios.transferencias_pendientes_resumen('','')


