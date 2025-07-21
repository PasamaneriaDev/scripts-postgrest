-- DROP FUNCTION ordenes_venta.pedido_esta_aprobado(p_numero_pedido character varying)

CREATE OR REPLACE FUNCTION ordenes_venta.pedido_esta_aprobado(p_numero_pedido character varying)
    RETURNS table
            (
                aprobado boolean,
                bodega   character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT CASE WHEN pc.bodega = '023' THEN TRUE ELSE pc.aprobacion_cambio END AS aprobado, pc.bodega
        FROM ordenes_venta.pedidos_cabecera pc
        WHERE pc.numero_pedido = p_numero_pedido;
END ;
$function$
;
