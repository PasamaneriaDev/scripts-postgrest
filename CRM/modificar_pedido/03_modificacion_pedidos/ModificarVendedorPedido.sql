-- DROP FUNCTION ordenes_venta.pedidos_cambio_vendedor_fnc(varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_cambio_vendedor_fnc(p_numero_pedido character varying, p_vendedor_nuevo character varying, p_usuario character varying)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$

DECLARE
    v_tipo_comision   CHARACTER VARYING;
    v_bodega          CHARACTER VARYING;
    v_codigo_venta    CHARACTER VARYING;
    r_pedido_cabecera RECORD;
    _interface_activo boolean;
BEGIN
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Validaciones
    p_numero_pedido = TRIM(p_numero_pedido);
    SELECT vendedor, codigo_venta, bodega
    INTO r_pedido_cabecera
    FROM ordenes_venta.pedidos_cabecera
    WHERE numero_pedido = p_numero_pedido;

    IF NOT found THEN
        RAISE EXCEPTION 'El número de pedido es incorrecto.';
    END IF;

    IF NOT EXISTS(SELECT codigo FROM ordenes_venta.vendedores WHERE codigo = p_vendedor_nuevo) THEN
        RAISE EXCEPTION 'El código de vendedor es incorrecto.';
    END IF;

    -- Obtener DATOS del vendedor
    SELECT tipo_comision
    INTO v_tipo_comision
    FROM ordenes_venta.vendedores
    WHERE codigo = p_vendedor_nuevo;

    -- Verifica la Ciudad del Vendedor
    IF LEFT(v_tipo_comision, 1) = 'C' THEN
        v_bodega = '001';
        v_codigo_venta = 'VFC';
    ELSEIF LEFT(v_tipo_comision, 1) = 'Q' THEN
        v_bodega = '101';
        v_codigo_venta = 'VFQ';
    ELSE
        RAISE EXCEPTION 'El vendedor no tiene un tipo de comisión válido (C/Q).';
    END IF;

    -- ACTUALIZACION de la Cabecera del Pedido
    WITH t AS (
        UPDATE ordenes_venta.pedidos_cabecera pc
            SET vendedor = p_vendedor_nuevo,
                codigo_venta = v_codigo_venta,
                bodega = v_bodega
            WHERE pc.numero_pedido = p_numero_pedido
            RETURNING pc.terminos_pago, pc.dias_plazo, pc.cliente)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, SQL)
    SELECT 'ORDENES DE VENTA',
           'UPDATE1',
           'Somast01',
           p_usuario,
           'V:\sbtpro\SODATA\',
           '',
           'UPDATE v:\sbtpro\SODATA\Somast01 ' ||
           'set glarec = [' || v_codigo_venta::VARCHAR || '], ' ||
           '  loctid = [' || rpad(v_bodega::VARCHAR, 3, ' ') || '], ' ||
           '  salesmn = [' || p_vendedor_nuevo::VARCHAR || '] ' ||
           'Where sono = [' || LPAD(p_numero_pedido::VARCHAR, 10, ' ') || '] '
    FROM t
    WHERE _interface_activo;

    -- ACTUALIZACION en el Detalle del Pedido
    UPDATE ordenes_venta.pedidos_detalle
    SET vendedor     = p_vendedor_nuevo,
        codigo_venta = v_codigo_venta,
        bodega       = v_bodega
    WHERE numero_pedido = p_numero_pedido;
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, SQL)
    SELECT 'ORDENES DE VENTA',
           'UPDATE1',
           'Sotran01',
           p_usuario,
           'V:\sbtpro\SODATA\',
           '',
           'UPDATE v:\sbtpro\SODATA\Sotran01 ' ||
           'set glsale = [' || v_codigo_venta::VARCHAR || '], ' ||
           '  loctid = [' || rpad(v_bodega::VARCHAR, 3, ' ') || '], ' ||
           '  salesmn = [' || p_vendedor_nuevo::VARCHAR || '] ' ||
           'Where sono = [' || LPAD(p_numero_pedido, 10, ' ') || '] '
    WHERE _interface_activo;

    -- insert en bitacora
    INSERT INTO ordenes_venta.pedidos_cabecera_bitacora
    (numero_pedido,
     vendedor_anterior,
     codigo_venta_anterior,
     bodega_anterior,
     vendedor_nuevo,
     codigo_venta_nuevo,
     bodega_nueva,
     creacion_usuario)
    VALUES (p_numero_pedido,
            r_pedido_cabecera.vendedor,
            r_pedido_cabecera.codigo_venta,
            r_pedido_cabecera.bodega,
            p_vendedor_nuevo,
            v_codigo_venta,
            v_bodega,
            p_usuario);

    /**********/
    RETURN TRUE;
    /**********/
END;
$function$
;
