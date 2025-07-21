-- DROP FUNCTION ordenes_venta.pedido_actualiza_plazo_x_cliente(in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION ordenes_venta.pedido_actualiza_plazo_x_cliente(p_numero_pedido character varying,
                                                                          p_usuario character varying,
                                                                          OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo boolean;
    r_pedido_cabecera RECORD;
BEGIN
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Original
    SELECT pc.dias_plazo,
           pc.terminos_pago,
           c.terminos_pago AS terminos_pago_cliente,
           c.dias_plazo    AS dias_plazo_cliente
    INTO r_pedido_cabecera
    FROM ordenes_venta.pedidos_cabecera pc
             JOIN cuentas_cobrar.clientes c ON pc.cliente = c.codigo
    WHERE pc.numero_pedido = p_numero_pedido;

    -- ACTUALIZACIÓN en la Cabecera del Pedido
    WITH t AS (
        UPDATE ordenes_venta.pedidos_cabecera pc
            SET terminos_pago = r_pedido_cabecera.terminos_pago_cliente,
                dias_plazo = r_pedido_cabecera.dias_plazo_cliente
            WHERE pc.numero_pedido = p_numero_pedido
            RETURNING pc.terminos_pago, pc.dias_plazo)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'ORDENES DE VENTA',
           'UPDATE1',
           'Somast01',
           p_usuario,
           'V:\sbtpro\SODATA\',
           '',
           'UPDATE v:\sbtpro\SODATA\Somast01 ' ||
           'set pterms = [' || t.terminos_pago || '], ' ||
           '  pnet = ' || t.dias_plazo || ' ' ||
           'Where sono = [' || LPAD(p_numero_pedido::varchar, 10, ' ') || '] '
    FROM t
    WHERE _interface_activo;

    -- Insert en la Bitácora de Cabecera
    INSERT INTO ordenes_venta.pedidos_cabecera_bitacora
    (numero_pedido,
     terminos_pago_anterior,
     dias_plazo_anterior,
     terminos_pago_nuevo,
     dias_plazo_nuevo,
     creacion_usuario)
    VALUES (p_numero_pedido,
            r_pedido_cabecera.terminos_pago,
            r_pedido_cabecera.dias_plazo,
            r_pedido_cabecera.terminos_pago_cliente,
            r_pedido_cabecera.dias_plazo_cliente,
            p_usuario);

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
