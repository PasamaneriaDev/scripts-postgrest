-- DROP FUNCTION puntos_venta.requerimientos_cambiar_estado_autorizado(integer, varchar, varchar, boolean);

CREATE OR REPLACE FUNCTION ordenes_venta.proforma_tipo_precio_x_cliente(p_id_cliente_consignacion integer,
                                                                        p_item varchar, OUT o_tipo_precio text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    reg_cliente RECORD;
BEGIN
    SELECT cc.bodega
    INTO reg_cliente
    FROM cuentas_cobrar.clientes_consignacion cc
    WHERE id_cliente_consignacion = p_id_cliente_consignacion;

    -- Busca el codigo de precio
    o_tipo_precio = 'MAY';
    IF reg_cliente.bodega = '162' THEN
        IF p_item LIKE 'BA%'
            OR p_item LIKE '2828%'
            OR p_item LIKE '2868%' THEN
            o_tipo_precio = 'PVP';
        END IF;
    END IF;

END;
$function$
;
