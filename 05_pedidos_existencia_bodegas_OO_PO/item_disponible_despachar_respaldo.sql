-- DROP FUNCTION ordenes_venta.item_disponible_despachar(varchar);

CREATE OR REPLACE FUNCTION ordenes_venta.item_disponible_despachar(p_item character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
      Lv_Paso character VARYING;
      registro RECORD;
      Ln_diasentrega numeric(2,0);
      Ln_montovencimiento numeric(2,0);
      Ln_disponible numeric(10,3):=0;
			Ln_disponible_c numeric(10,3):=0;

BEGIN
	select numero INTO Ln_diasentrega from sistema.parametros where codigo='DIAS_ENTREG_PED';
	select numero INTO Ln_montovencimiento from sistema.parametros where codigo='MONTO_VENCIMIEN';

	Lv_Paso = 'Paso 1. Obtiene total de existencias por item';
  --Totaliza las existencias por bodega. Y para los clientes especiales (MEGAMAXI, ETAFASHION) totaliza por
  --cliente considerando únicamente las ubicaciones especiales de estos clientes.
	--create temp table exisubic
  DROP table IF EXISTS ordenes_venta.exisubic;
  create table ordenes_venta.exisubic
	as
	select LPAD(COALESCE(c.cliente,''),6,' ') cliente,u.bodega,sum(u.existencia) existencia,0 as disponible
	from control_inventarios.ubicaciones u left JOIN ordenes_venta.clientes_ubicaciones c on u.bodega=c.bodega and u.ubicacion=c.ubicacion
	where u.item=p_item  AND (u.existencia - u.comprometido_despacho) > 0
	group by c.cliente,u.bodega;

  Lv_Paso = 'Paso 1.1. Obtiene total de comprometido para despacho';
  DROP table IF EXISTS ordenes_venta.auxcomprometido;
  create table ordenes_venta.auxcomprometido
	as
	select t1.cliente,t1.bodega,sum(t1.cantidad_pendiente) comprometido,0 as disponible
	from ordenes_venta.orden_despacho t1
	where t1.item=p_item  AND t1.cantidad_pendiente>0 and COALESCE(t1.estado,'')=''
	group by t1.cliente,t1.bodega;


  Lv_Paso = 'Paso 2. Obtiene pedidos pendientes';
  --Obtiene los pedidos pendientes: No asigna el disponible para los clientes que tienen: vencimientos, clientes dudosos,
  --clientes anulados, clientes que tienen cheques protestados.
  --create temp table pedipend
DROP table ordenes_venta.pedipend;
create table ordenes_venta.pedipend
	as
	select d.bodega,'      '::VARCHAR as cliente_ubic,d.cliente,d.numero_pedido,d.fecha_pedido,cab.fecha_entrega,d.item,d.cantidad_pendiente,
                         0 as cantidad_despacho, c.es_dudoso, c.status,LEFT(C.banderas,1) as verifica_vencimiento,
												 EXISTS (SELECT 1
																 from cuentas_cobrar.facturas_cabecera f
																 where f.balance > 5 and COALESCE(f.status,'')<>'ANULADO' AND (CURRENT_DATE - f.fecha - CASE WHEN f.dias_plazo_manual>0 THEN f.dias_plazo_manual ELSE f.dias_plazo END >15)
																	 AND f.cliente = d.cliente
																) as tiene_vencimiento,
												EXISTS(select c.codigo
																from cheques.clientes c
																where c.protestados > 0 AND COALESCE(c.codigo,'')<>'' AND COALESCE(c.status,'')=''
																		AND c.codigo = d.cliente
															) as protestado
									from ordenes_venta.pedidos_detalle d
											 INNER JOIN cuentas_cobrar.clientes c on d.cliente=c.codigo
											 INNER JOIN ordenes_venta.pedidos_cabecera cab on d.numero_pedido = cab.numero_pedido
									where d.item = p_item and not COALESCE(d.estado,'') in  ('C','V','-','X') and COALESCE(d.tipo_pedido,'')<>'B' and
												d.cantidad_pendiente>0 and COALESCE(c.status,'')='' and COALESCE(c.es_dudoso,'') <> 'DU';

  Lv_Paso = 'Paso 4. Coloca código de clientes que tienen ubicaciones especiales';
  --Por ejemplo: MEGAMAXI, ETAFASHION, se despachan unicamente de las ubicaciones que les corresponden.
	update ordenes_venta.pedipend p
	set cliente_ubic = e.cliente
	from ordenes_venta.exisubic e
	where p.cliente = e.cliente;

	Lv_Paso = 'Paso 5. --Calcula disponible de pedidos que no tienen vencimientos';
	FOR registro IN ( select * from ordenes_venta.pedipend
										where verifica_vencimiento<>'V' or
                          (verifica_vencimiento='V' and tiene_vencimiento=FALSE and protestado=FALSE)
                    order by bodega,fecha_pedido,numero_pedido
                  ) LOOP

			UPDATE ordenes_venta.exisubic
			Set disponible = case when existencia > registro.cantidad_pendiente::NUMERIC then registro.cantidad_pendiente::NUMERIC else existencia end,
					existencia = case when existencia > registro.cantidad_pendiente::NUMERIC then existencia - registro.cantidad_pendiente::NUMERIC else 0 end
			Where cliente = registro.cliente_ubic::VARCHAR and bodega = registro.bodega::VARCHAR
			RETURNING disponible INTO Ln_disponible;

			Ln_disponible = COALESCE(Ln_disponible,0);

			registro.cantidad_pendiente = registro.cantidad_pendiente - Ln_disponible;

			UPDATE ordenes_venta.auxcomprometido
			Set disponible = case when comprometido > registro.cantidad_pendiente::NUMERIC then registro.cantidad_pendiente::NUMERIC else comprometido end,
					comprometido = case when comprometido > registro.cantidad_pendiente::NUMERIC then comprometido - registro.cantidad_pendiente::NUMERIC else 0 end
			Where cliente = registro.cliente::VARCHAR and bodega = registro.bodega::VARCHAR
			RETURNING disponible INTO Ln_disponible_c;

			Ln_disponible = Ln_disponible + COALESCE(Ln_disponible_c,0);


			update ordenes_venta.pedipend
			   set cantidad_despacho = Ln_disponible
      where numero_pedido = registro.numero_pedido::VARCHAR and item= registro.item::VARCHAR;

	END LOOP;

EXCEPTION
     WHEN OTHERS THEN
        RAISE EXCEPTION 'Falló item: %.El error fue: % Ubicacion %',p_item,SQLERRM,Lv_Paso;
        END;
$function$
;
