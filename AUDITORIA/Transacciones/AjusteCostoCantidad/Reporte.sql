-- DROP FUNCTION control_inventarios.ajustes_imprimir(text, date, date, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajustes_imprimir(p_documento text, p_fecha_inicial date, p_fecha_final date, usuario text)
 RETURNS TABLE(documento character varying, creacion_fecha date, fecha date, bodega character varying, ubicacion character varying, item character varying, item_descripcion character varying, anio_trimestre numeric, costo numeric, costo_nuevo numeric, grupo text, cantidad_anterior numeric, cantidad_nueva numeric, documento_descripcion text)
 LANGUAGE plpgsql
AS $function$

BEGIN

IF p_documento <> '' THEN
	RETURN query
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
		 where a.documento = p_documento
	ORDER BY grupo;

ELSE
	RETURN query
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
	 WHERE a.creacion_fecha BETWEEN p_fecha_inicial AND p_fecha_final
    ORDER BY grupo;

end if;

END;
$function$
;
