-- DROP FUNCTION ordenes_venta.proforma_genera_x_toma_inventario(in int4, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION ordenes_venta.proforma_genera_x_toma_inventario(p_id_cliente_consignacion integer,
                                                                           p_bodega_entorno character varying,
                                                                           p_usuario character varying,
                                                                           OUT o_numero_pedido text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo        boolean;
    v_tipos_precio           text = 'MAY';
    v_item_validacion        text;
    v_iva                    numeric;
    v_monto_subtotal         numeric;
    v_monto_iva              numeric;
    v_tipo_precio_rg         text;
    reg_cliente              RECORD;
    v_numero_pedido_generado text;

BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Busca el cliente de consignacion
    SELECT cc.bodega, cc.dias_plazo, c.nombre, c.codigo, c.territorio, c.vendedor
    INTO reg_cliente
    FROM cuentas_cobrar.clientes_consignacion cc
             JOIN cuentas_cobrar.clientes c ON cc.codigo = c.codigo
    WHERE id_cliente_consignacion = p_id_cliente_consignacion;

    IF NOT found THEN
        RAISE EXCEPTION 'No existe el cliente de consignacion %', p_id_cliente_consignacion;
    END IF;

    -- Busca el Iva
    SELECT pa.iva
    INTO v_iva
    FROM sistema.parametros_almacenes pa
    WHERE pa.bodega = p_bodega_entorno;

    DROP TABLE IF EXISTS _ajustes_proforma_temp;
    CREATE TEMPORARY TABLE _ajustes_proforma_temp AS
    SELECT *, v_tipos_precio AS tipo_precio, 0 AS porcentaje_descuento
    FROM control_inventarios.ajustes a
    WHERE a.bodega = reg_cliente.bodega
      AND a.tipo = 'T'
      AND a.status = '';

    -- Verificamos que exista la toma
    IF NOT EXISTS (SELECT 1
                   FROM _ajustes_proforma_temp a) THEN
        RAISE EXCEPTION 'No existe nada para Facturar';
    END IF;

    -- Busca codigos de precio
    IF reg_cliente.codigo = '108001' THEN
        UPDATE _ajustes_proforma_temp
        SET tipo_precio          = 'PVP',
            porcentaje_descuento = 20
        WHERE (item LIKE 'BA%'
            OR item LIKE '2828%'
            OR item LIKE '2868%');

        IF found THEN
            v_tipos_precio = v_tipos_precio || ',PVP';
        END IF;
    END IF;

    -- Itera los tipos de precio
    FOR v_tipo_precio_rg IN
        SELECT UNNEST(('{' || v_tipos_precio || '}')::text[])
        LOOP
            -- Verificamos que existan items y precios
            SELECT a.item
            INTO v_item_validacion
            FROM _ajustes_proforma_temp a
                     LEFT JOIN control_inventarios.items i ON a.item = i.item
                     LEFT JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = a.tipo_precio
            WHERE a.tipo_precio = v_tipo_precio_rg
              AND p.item IS NULL
            LIMIT 1;

            IF FOUND THEN
                RAISE EXCEPTION 'No se encontro item o precio para el siguiente codigo: %, con precio: %', v_item_validacion, v_tipo_precio_rg;
            END IF;

            -- Preparamos Detalle
            DROP TABLE IF EXISTS _pedido_detalle_temp;
            CREATE TEMPORARY TABLE _pedido_detalle_temp AS
            SELECT reg_cliente.codigo               AS codigo_cliente,
                   a.item,
                   i.descripcion,
                   v_iva                            AS iva,
                   b.existencia - a.cantidad_ajuste AS cantidad,
                   i.costo_promedio,
                   p.precio,
                   reg_cliente.territorio,
                   reg_cliente.vendedor,
                   'VFQ'                            AS codigo_venta,
                   'PRT'                            AS codigo_inventario,
                   TRUE                             AS es_stock,
                   TRUE                             AS tiene_iva,
                   p.tipo                           AS tipo_precio,
                   a.porcentaje_descuento,
                   a.bodega,
                   'B'                              AS tipo_pedido,
                   p_usuario                        AS creacion_usuario
            FROM _ajustes_proforma_temp a
                     JOIN control_inventarios.items i ON a.item = i.item
                     JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = a.tipo_precio
                     LEFT JOIN control_inventarios.bodegas b ON b.item = a.item AND b.bodega = a.bodega
            WHERE a.tipo_precio = v_tipo_precio_rg
              AND a.cantidad_ajuste < b.existencia;

            IF EXISTS(SELECT 1 FROM _pedido_detalle_temp) THEN
                -- Busca el nuevo numero de pedido
                SELECT numero::varchar
                INTO v_numero_pedido_generado
                FROM sistema.pedido_numero_obtener(p_bodega_entorno);

                -- Totaliza
                WITH detalle_calculado AS (SELECT precio * cantidad AS subtotal
                                           FROM _pedido_detalle_temp)
                SELECT SUM(ROUND(subtotal, 2)),
                       ROUND(SUM(subtotal * (v_iva / 100)), 2)
                INTO v_monto_subtotal, v_monto_iva
                FROM detalle_calculado;

                WITH cte AS (
                    INSERT
                        INTO ordenes_venta.pedidos_cabecera AS pc (numero_pedido, cliente, fecha_pedido, porcentaje_iva,
                                                                   territorio, vendedor, codigo_venta, tipo_precio,
                                                                   bodega, monto_pendiente, tipo_pedido, terminos_pago,
                                                                   monto_iva, dias_plazo, creacion_usuario,
                                                                   creacion_fecha, creacion_hora)
                            SELECT v_numero_pedido_generado,
                                   reg_cliente.codigo,
                                   CURRENT_DATE,
                                   v_iva,
                                   reg_cliente.territorio,
                                   reg_cliente.vendedor,
                                   'VFQ',
                                   v_tipo_precio_rg,
                                   reg_cliente.bodega,
                                   v_monto_subtotal + v_monto_iva,
                                   'B',
                                   'FACTURA',
                                   v_monto_iva,
                                   reg_cliente.dias_plazo,
                                   p_usuario,
                                   CURRENT_DATE,
                                   TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS')
                            RETURNING pc.numero_pedido, pc.cliente, pc.fecha_pedido, pc.porcentaje_iva,
                                pc.territorio, pc.vendedor, pc.codigo_venta, pc.tipo_precio, pc.bodega,
                                pc.monto_pendiente, pc.tipo_pedido, pc.terminos_pago, pc.monto_iva,
                                pc.dias_plazo, pc.creacion_usuario, pc.creacion_fecha, pc.creacion_hora)
                INSERT
                INTO sistema.interface
                    (modulo, proceso, tabla, directorio, usuarios, buscar, sql)
                SELECT 'ORDENES DE VENTA'
                     , 'INSERT1'
                     , 'SOMAST01'
                     , 'V:\SBTPRO\SODATA\ '
                     , p_usuario
                     , ''
                     , FORMAT('Insert Into V:\SBTPRO\SODATA\SOMAST01 ' ||
                              '(custno, sodate, taxrate, terr, salesmn, ' ||
                              ' glarec, pricecode, loctid, ordamt, sotype, ' ||
                              ' pterms, tax, adduser, adddate, addtime, ' ||
                              ' pnet, sono) ' ||
                              'Values ([%s], [%s], %s, [%s], [%s], ' ||
                              '        [%s], [%s], [%s], %s, [%s], ' ||
                              '        [%s], %s, [%s], {^%s}, [%s], ' ||
                              '        %s, [%s])',
                              c.cliente, TO_CHAR(c.fecha_pedido, 'MM/DD/YYYY'), c.porcentaje_iva, c.territorio,
                              c.vendedor,
                              c.codigo_venta, c.tipo_precio, RPAD(c.bodega, 3, ' '), c.monto_pendiente, c.tipo_pedido,
                              c.terminos_pago, c.monto_iva, c.creacion_usuario, TO_CHAR(c.creacion_fecha, 'YYYY-MM-DD'),
                              c.creacion_hora,
                              c.dias_plazo, RIGHT('     ' || c.numero_pedido, 10))
                FROM cte c
                WHERE _interface_activo;

                WITH cte AS (
                    INSERT INTO ordenes_venta.pedidos_detalle AS pd (numero_pedido, cliente, item, descripcion,
                                                                     fecha_pedido, fecha_original_pedido,
                                                                     porcentaje_iva, cantidad_pendiente,
                                                                     cantidad_original, costo, precio, subtotal,
                                                                     porcentaje_descuento,
                                                                     territorio, vendedor, codigo_venta,
                                                                     codigo_inventario, es_stock, tiene_iva,
                                                                     tipo_precio, bodega, tipo_pedido, creacion_usuario,
                                                                     creacion_fecha, creacion_hora)
                        SELECT v_numero_pedido_generado,
                               codigo_cliente,
                               item,
                               descripcion,
                               CURRENT_DATE,
                               CURRENT_DATE,
                               iva,
                               cantidad,
                               cantidad,
                               costo_promedio,
                               precio,
                               ROUND((precio * cantidad), 2),
                               porcentaje_descuento,
                               territorio,
                               vendedor,
                               codigo_venta,
                               codigo_inventario,
                               es_stock,
                               tiene_iva,
                               tipo_precio,
                               bodega,
                               tipo_pedido,
                               creacion_usuario,
                               CURRENT_DATE,
                               TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS')
                        FROM _pedido_detalle_temp
                        RETURNING pd.numero_pedido, pd.cliente, pd.item, pd.descripcion, pd.fecha_pedido, pd.fecha_original_pedido,
                            pd.porcentaje_iva, pd.cantidad_pendiente, pd.cantidad_original, pd.costo, pd.precio, pd.subtotal, pd.porcentaje_descuento,
                            pd.territorio, pd.vendedor, pd.codigo_venta, pd.codigo_inventario, pd.es_stock, pd.tiene_iva,
                            pd.tipo_precio, pd.bodega, pd.tipo_pedido, pd.creacion_usuario, pd.creacion_fecha, pd.creacion_hora,
                            pd.secuencia)
                INSERT
                INTO sistema.interface
                    (modulo, proceso, tabla, directorio, usuarios, buscar, sql)
                SELECT 'ORDENES DE VENTA'
                     , 'INSERT1'
                     , 'SOTRAN01'
                     , 'V:\SBTPRO\SODATA\ '
                     , p_usuario
                     , ''
                     , FORMAT('Insert Into V:\SBTPRO\SODATA\SOTRAN01 ' ||
                              '(custno, item, descrip, ordate, fecped, taxrate, ' ||
                              ' qtyord, qtyord_o, cost, price, extprice, terr, ' ||
                              ' salesmn, glsale, glasst, stkcode, taxable, pricecode, ' ||
                              ' loctid, sotype, adduser, adddate, addtime, ' ||
                              ' sono, secu_post, disc) ' ||
                              'Values ([%s], [%s], [%s], [%s], [%s], %s,' ||
                              '        %s, %s, %s, %s, %s, [%s], ' ||
                              '        [%s], [%s], [%s], [%s], [%s], [%s], ' ||
                              '        [%s], [%s], [%s], {^%s}, [%s], ' ||
                              '        [%s], %s, %s)',
                              c.cliente, c.item, c.descripcion, TO_CHAR(c.fecha_original_pedido, 'MM/DD/YYYY'),
                              TO_CHAR(c.fecha_pedido, 'MM/DD/YYYY'), c.porcentaje_iva,
                              c.cantidad_pendiente, c.cantidad_original, c.costo, c.precio, c.subtotal, c.territorio,
                              c.vendedor, c.codigo_venta, c.codigo_inventario,
                              CASE WHEN c.es_stock THEN 'Y' ELSE 'N' END,
                              CASE WHEN c.tiene_iva THEN 'Y' ELSE 'N' END, c.tipo_precio,
                              RPAD(c.bodega, 3, ' '), c.tipo_pedido, c.creacion_usuario,
                              TO_CHAR(c.creacion_fecha, 'YYYY-MM-DD'),
                              c.creacion_hora,
                              RIGHT('     ' || c.numero_pedido, 10), c.secuencia, c.porcentaje_descuento)
                FROM cte c
                WHERE _interface_activo;

                IF COALESCE(o_numero_pedido, '') = '' THEN
                    o_numero_pedido = v_numero_pedido_generado;
                ELSE
                    o_numero_pedido = COALESCE(o_numero_pedido, '') || ',' || v_numero_pedido_generado;
                END IF;
            END IF;
        END LOOP;

    IF COALESCE(o_numero_pedido, '') = '' THEN
        RAISE EXCEPTION 'No hay nada pendiente por despachar para %', reg_cliente.nombre;
    END IF;

    -- Actualiza los ajustes
    UPDATE control_inventarios.ajustes a
    SET status = 'C'
    WHERE bodega = reg_cliente.bodega
      AND tipo = 'T'
      AND status = '';

    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT p_usuario
         , 'ORDENES DE VENTA'
         , 'UPDATE1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , FORMAT(
            'UPDATE v:\sbtpro\icdata\ICINVF01 ' ||
            'SET icstat = [C] ' ||
            'WHERE loctid = [%s] ' ||
            '  AND empty(icstat) ' ||
            '  AND type = [T]',
            RPAD(reg_cliente.bodega, 3, ' '))
    WHERE _interface_activo;
END;
$function$
;
