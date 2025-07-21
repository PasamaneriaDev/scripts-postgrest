-- drop FUNCTION ordenes_venta.pedidos_usuario_modifica_cabecera(p_codigo_usuario VARCHAR)

CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_usuario_modifica_cabecera(p_codigo_usuario VARCHAR, OUT respuesta BOOLEAN)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    SELECT EXISTS (SELECT 1
                   FROM sistema.accesos_ventana_accion ava
                   WHERE AVA.modulo = 'MODIFICA_CABECERA_PEDIDO'
                     AND ava.usuario_id = p_codigo_usuario)
    INTO respuesta;

    RETURN;
END;
$function$;


