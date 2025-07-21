-- drop FUNCTION ordenes_venta.pedidos_cambio_cliente_fnc(p_numero_pedido character varying, p_cliente_nuevo character varying, p_usuario varchar)
CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_cambio_cliente_fnc(p_numero_pedido character varying,
                                                                    p_cliente_nuevo character varying,
                                                                    p_usuario varchar)
    RETURNS boolean
    LANGUAGE plpgsql
AS
$function$

DECLARE
    Lc_terminos_pago           CHARACTER VARYING;
    Ln_dias_plazo              NUMERIC;
    _interface_activo          boolean;
    Ln_Subtotal                NUMERIC;
    Ln_monto_iva               NUMERIC;
    Ln_monto_pendiente         NUMERIC;
    Ln_porcentaje_iva          NUMERIC;
    r_pedido_cabecera_original RECORD;
BEGIN
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Validaciones
    p_numero_pedido = TRIM(p_numero_pedido);
    SELECT cliente,
           terminos_pago,
           dias_plazo,
           monto_iva,
           monto_pendiente
    INTO r_pedido_cabecera_original
    FROM ordenes_venta.pedidos_cabecera
    WHERE numero_pedido = p_numero_pedido;

    IF NOT found THEN
        RAISE EXCEPTION 'El número de pedido es incorrecto.';
    END IF;

    IF NOT EXISTS(SELECT codigo FROM cuentas_cobrar.clientes WHERE codigo = p_cliente_nuevo) THEN
        RAISE EXCEPTION 'El código de cliente es incorrecto.';
    END IF;

    IF p_cliente_nuevo = '' OR p_numero_pedido = '' THEN
        RAISE EXCEPTION 'No se enviaron los datos necesarios para la actualización.';
    END IF;

    -- Obtener los datos del cliente
    SELECT terminos_pago, dias_plazo, COALESCE(iva, 0) / 100
    INTO Lc_terminos_pago, Ln_dias_plazo, Ln_porcentaje_iva
    FROM cuentas_cobrar.clientes
    WHERE codigo = p_cliente_nuevo;

    -- Calcula los nuevo totales
    SELECT SUM(t1.subtotal)
    INTO Ln_Subtotal
    FROM ordenes_venta.pedidos_detalle t1
    WHERE t1.numero_pedido = p_numero_pedido
      AND t1.cliente = r_pedido_cabecera_original.cliente
      AND t1.cantidad_pendiente > 0
      AND COALESCE(t1.estado, '') = ''
      AND COALESCE(t1.tipo_pedido, '') <> 'B';

    Ln_Subtotal = ROUND(COALESCE(Ln_Subtotal, 0), 2);
    Ln_monto_iva = ROUND((Ln_Subtotal * Ln_porcentaje_iva), 2);
    Ln_monto_pendiente = ROUND(Ln_Subtotal + Ln_monto_iva, 2);

    -- ACTUALIZACIÓN en la Cabecera del Pedido
    WITH t AS (
        UPDATE ordenes_venta.pedidos_cabecera pc
            SET cliente = p_cliente_nuevo,
                terminos_pago = Lc_terminos_pago,
                dias_plazo = Ln_dias_plazo,
                monto_iva = Ln_monto_iva,
                monto_pendiente = Ln_monto_pendiente
            WHERE pc.numero_pedido = p_numero_pedido
            RETURNING pc.terminos_pago, pc.dias_plazo, pc.cliente, pc.monto_iva, pc.monto_pendiente)
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
           'set custno = [' || t.cliente || '], ' ||
           '  pterms = [' || t.terminos_pago || '], ' ||
           '  pnet = ' || t.dias_plazo::varchar || ', ' ||
           '  tax = ' || t.monto_iva::varchar || ', ' ||
           '  ordamt = ' || t.monto_pendiente::varchar || ' ' ||
           'Where sono = [' || LPAD(p_numero_pedido::varchar, 10, ' ') || '] '
    FROM t
    WHERE _interface_activo;

    -- ACTUALIZACIÓN del Saldo del cliente
    WITH t AS (
        UPDATE cuentas_cobrar.clientes t1
            SET pedidos = (SELECT SUM(t2.monto_pendiente)
                           FROM ordenes_venta.pedidos_cabecera t2
                           WHERE t1.codigo = t2.cliente
                             AND t2.monto_pendiente > 0
                             AND COALESCE(t2.estado, '') = '')
            WHERE t1.codigo = p_cliente_nuevo
            RETURNING t1.pedidos)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'CUENTAS POR COBRAR',
           'UPDATE1',
           'Arcust01',
           p_usuario,
           'V:\sbtpro\ARDATA',
           '',
           'UPDATE V:\sbtpro\ARDATA\Arcust01 ' ||
           'set onorder = ' || t.pedidos::varchar || ' ' ||
           'Where custno = [' || p_cliente_nuevo || '] '
    FROM t
    WHERE _interface_activo;

    -- ACTUALIZACIÓN en el Detalle del Pedido
    UPDATE ordenes_venta.pedidos_detalle
    SET cliente = p_cliente_nuevo
    WHERE numero_pedido = p_numero_pedido;

    IF found THEN
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'ORDENES DE VENTA',
               'UPDATE1',
               'Sotran01',
               p_usuario,
               'V:\sbtpro\SODATA\',
               '',
               'UPDATE v:\sbtpro\SODATA\Sotran01 ' ||
               'set custno = [' || p_cliente_nuevo::varchar || '] ' ||
               'Where sono = [' || LPAD(p_numero_pedido, 10, ' ') || '] '
        WHERE _interface_activo;
    END IF;

    -- ACTUALIZACIÓN
    UPDATE ordenes_venta.pedidos_detalle_comprometido
    SET cliente = p_cliente_nuevo
    WHERE numero_pedido = p_numero_pedido;

    IF found THEN
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'ORDENES DE VENTA',
               'UPDATE1',
               'sotran_c',
               p_usuario,
               'V:\sbtpro\SODATA\',
               '',
               'UPDATE v:\sbtpro\SODATA\sotran_c ' ||
               'set custno = [' || p_cliente_nuevo::varchar || '] ' ||
               'Where sono = [' || LPAD(p_numero_pedido, 10, ' ') || '] '
        WHERE _interface_activo;
    END IF;

    -- ACTUALIZACION
    UPDATE ordenes_venta.despachos_pedidos dp
    SET cliente = p_cliente_nuevo
    WHERE dp.numero_pedido = p_numero_pedido;

    IF found THEN
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'ORDENES DE VENTA',
               'UPDATE1',
               'desppedi',
               p_usuario,
               'V:\sbtpro\SODATA\',
               '',
               'UPDATE v:\sbtpro\SODATA\desppedi ' ||
               'set custno = [' || p_cliente_nuevo::varchar || '] ' ||
               'Where sono = [' || LPAD(p_numero_pedido, 10, ' ') || '] '
        WHERE _interface_activo;
    END IF;
    -- ACTUALIZACION

    UPDATE ordenes_venta.orden_despacho od
    SET cliente = p_cliente_nuevo
    WHERE od.numero_pedido = p_numero_pedido;

    IF found THEN
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'ORDENES DE VENTA',
               'UPDATE1',
               'sodesp01',
               p_usuario,
               'V:\sbtpro\SODATA\',
               '',
               'UPDATE v:\sbtpro\SODATA\sodesp01 ' ||
               'set custno = [' || p_cliente_nuevo::varchar || '] ' ||
               'Where sono = [' || LPAD(p_numero_pedido, 10, ' ') || '] '
        WHERE _interface_activo;
    END IF;

    -- INSERT EN BITACORA
    INSERT INTO ordenes_venta.pedidos_cabecera_bitacora
    (numero_pedido, cliente_anterior, terminos_pago_anterior, dias_plazo_anterior, monto_iva_anterior,
     monto_pendiente_anterior, cliente_nuevo, terminos_pago_nuevo, dias_plazo_nuevo, monto_iva_nuevo,
     monto_pendiente_nuevo, creacion_usuario)
    VALUES (p_numero_pedido,
            r_pedido_cabecera_original.cliente,
            r_pedido_cabecera_original.terminos_pago,
            r_pedido_cabecera_original.dias_plazo,
            r_pedido_cabecera_original.monto_iva,
            r_pedido_cabecera_original.monto_pendiente,
            p_cliente_nuevo,
            Lc_terminos_pago,
            Ln_dias_plazo,
            Ln_monto_iva,
            Ln_monto_pendiente,
            p_usuario);

    /***********/
    RETURN TRUE;
    /***********/
END;
$function$
;

