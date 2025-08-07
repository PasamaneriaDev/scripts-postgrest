-- DROP FUNCTION mercantil_tosi.procesar_ventas_semanales(in date, in date, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION mercantil_tosi.procesar_ventas_semanales(p_fecha_inicial date, p_fecha_final date,
                                                                    p_bodega_entorno character varying,
                                                                    p_usuario character varying,
                                                                    OUT o_numero_pedido text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo        BOOLEAN = TRUE;
    reg_cliente              RECORD;
    v_item_validacion        text;
    v_iva                    numeric;
    v_monto_subtotal         numeric;
    v_monto_iva              numeric;
    v_numero_pedido_generado text;
    v_tipo_pedido            text;
    v_fact                   text;
    v_dev                    text;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Busca el cliente de consignacion
    SELECT 'C40' AS bodega, c.dias_plazo, c.nombre, c.codigo, c.territorio, c.vendedor
    INTO reg_cliente
    FROM cuentas_cobrar.clientes c
    WHERE c.codigo = '200101';

    -- Busca el Iva
    SELECT pa.iva
    INTO v_iva
    FROM sistema.parametros_almacenes pa
    WHERE pa.bodega = '001';

    DROP TABLE IF EXISTS _ventas_proforma_temp;
    CREATE TEMPORARY TABLE _ventas_proforma_temp AS
    WITH cte AS (SELECT i.item,
                        SUM(a.qty) AS cantidad
                 FROM mercantil_tosi.ventas_pasa_semanal a
                          JOIN control_inventarios.items i ON a.item = i.item
                 WHERE TO_DATE(a.fecha, 'DD/MM/YYYY') BETWEEN p_fecha_inicial AND p_fecha_final
                   AND NOT a.procesado
                 GROUP BY i.item)
    SELECT a.item,
           a.cantidad,
           (CASE WHEN a.cantidad > 0 THEN '' ELSE 'R' END)::text AS tipo_pedido,
           0                                                     AS porcentaje_descuento,
           'C40'                                                 AS bodega
    FROM cte a
    WHERE a.cantidad <> 0;

    -- Verificamos que exista la toma
    IF NOT EXISTS (SELECT 1
                   FROM _ventas_proforma_temp a) THEN
        RAISE EXCEPTION 'No existe nada para Procesar';
    END IF;

    -- Verificamos que existan items y precios
    SELECT a.item
    INTO v_item_validacion
    FROM _ventas_proforma_temp a
             LEFT JOIN control_inventarios.precios p ON a.item = p.item AND p.tipo = 'MER'
    WHERE p.item IS NULL
    LIMIT 1;

    IF FOUND THEN
        RAISE EXCEPTION 'No se encontro item o precio para el siguiente codigo: %, con precio: %', v_item_validacion, 'MER';
    END IF;

    FOR v_tipo_pedido IN
        SELECT tipo_pedido FROM _ventas_proforma_temp GROUP BY tipo_pedido
        LOOP

            RAISE NOTICE 'Procesando tipo de pedido: %', v_tipo_pedido;
            -- Preparamos Detalle
            DROP TABLE IF EXISTS _pedido_detalle_temp;
            CREATE TEMPORARY TABLE _pedido_detalle_temp AS
            SELECT reg_cliente.codigo AS codigo_cliente,
                   a.item,
                   i.descripcion,
                   v_iva              AS iva,
                   -- b.existencia - a.cantidad AS cantidad,
                   a.cantidad         AS cantidad,
                   i.costo_promedio,
                   p.precio,
                   reg_cliente.territorio,
                   reg_cliente.vendedor,
                   'VFC'              AS codigo_venta,
                   'PRT'              AS codigo_inventario,
                   TRUE               AS es_stock,
                   TRUE               AS tiene_iva,
                   p.tipo             AS tipo_precio,
                   a.porcentaje_descuento,
                   a.bodega,
                   a.tipo_pedido      AS tipo_pedido,
                   p_usuario          AS creacion_usuario
            FROM _ventas_proforma_temp a
                     JOIN control_inventarios.items i ON a.item = i.item
                     JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = 'MER'
                     LEFT JOIN control_inventarios.bodegas b ON b.item = a.item AND b.bodega = a.bodega::varchar
            WHERE a.tipo_pedido::text = v_tipo_pedido::text;
            -- AND a.cantidad_ajuste < b.existencia;

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
                                                                   monto_iva, dias_plazo, despachar_pedido,
                                                                   creacion_usuario, creacion_fecha, creacion_hora)
                            SELECT v_numero_pedido_generado,
                                   reg_cliente.codigo,
                                   CURRENT_DATE,
                                   v_iva,
                                   reg_cliente.territorio,
                                   reg_cliente.vendedor,
                                   'VFC',
                                   'MER',
                                   reg_cliente.bodega,
                                   v_monto_subtotal + v_monto_iva,
                                   v_tipo_pedido,
                                   'FACTURA',
                                   v_monto_iva,
                                   reg_cliente.dias_plazo,
                                   (v_tipo_pedido = ''), -- Si es Factura, despachar pedido
                                   p_usuario,
                                   CURRENT_DATE,
                                   TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS')
                            RETURNING pc.numero_pedido, pc.cliente, pc.fecha_pedido, pc.porcentaje_iva,
                                pc.territorio, pc.vendedor, pc.codigo_venta, pc.tipo_precio, pc.bodega,
                                pc.monto_pendiente, pc.tipo_pedido, pc.terminos_pago, pc.monto_iva,
                                pc.dias_plazo, pc.creacion_usuario, pc.creacion_fecha, pc.creacion_hora,
                                pc.despachar_pedido)
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
                              '(custno, ordate, taxrate, terr, salesmn, ' ||
                              ' glarec, pricecode, loctid, ordamt, sotype, ' ||
                              ' pterms, tax, adduser, adddate, addtime, ' ||
                              ' pnet, sono, taxsamt, despachar) ' ||
                              'Values ([%s], [%s], %s, [%s], [%s], ' ||
                              '        [%s], [%s], [%s], %s, [%s], ' ||
                              '        [%s], %s, [%s], {^%s}, [%s], ' ||
                              '        %s, [%s], %s, %s)',
                              c.cliente, TO_CHAR(c.fecha_pedido, 'MM/DD/YYYY'), c.porcentaje_iva, c.territorio,
                              c.vendedor,
                              c.codigo_venta, c.tipo_precio, RPAD(c.bodega, 3, ' '), c.monto_pendiente, c.tipo_pedido,
                              c.terminos_pago, c.monto_iva, c.creacion_usuario, TO_CHAR(c.creacion_fecha, 'YYYY-MM-DD'),
                              c.creacion_hora,
                              c.dias_plazo, RIGHT('     ' || c.numero_pedido, 10),
                              ROUND((c.monto_pendiente - c.monto_iva), 2),
                              CASE WHEN c.despachar_pedido THEN '.t.' ELSE '.f.' END)
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
                              ' sono, secu_post, disc, code) ' ||
                              'Values ([%s], [%s], [%s], [%s], [%s], %s,' ||
                              '        %s, %s, %s, %s, %s, [%s], ' ||
                              '        [%s], [%s], [%s], [%s], [%s], [%s], ' ||
                              '        [%s], [%s], [%s], {^%s}, [%s], ' ||
                              '        [%s], %s, %s, [%s])',
                              c.cliente, c.item, c.descripcion, TO_CHAR(c.fecha_original_pedido, 'MM/DD/YYYY'),
                              TO_CHAR(c.fecha_pedido, 'MM/DD/YYYY'), c.porcentaje_iva,
                              c.cantidad_pendiente, c.cantidad_original, c.costo, c.precio, c.subtotal, c.territorio,
                              c.vendedor, c.codigo_venta, c.codigo_inventario,
                              CASE WHEN c.es_stock THEN 'Y' ELSE 'N' END,
                              CASE WHEN c.tiene_iva THEN 'Y' ELSE 'N' END, c.tipo_precio,
                              RPAD(c.bodega, 3, ' '), c.tipo_pedido, c.creacion_usuario,
                              TO_CHAR(c.creacion_fecha, 'YYYY-MM-DD'),
                              c.creacion_hora,
                              RIGHT('     ' || c.numero_pedido, 10), c.secuencia, c.porcentaje_descuento,
                              i.codigo_rotacion)
                FROM cte c
                         JOIN control_inventarios.items i ON c.item = i.item
                WHERE _interface_activo;

                IF v_tipo_pedido = '' THEN
                    IF COALESCE(o_numero_pedido, '') = '' THEN
                        v_fact = v_numero_pedido_generado;
                    ELSE
                        v_fact = COALESCE(v_fact, '') || ',' || v_numero_pedido_generado;
                    END IF;
                ELSE
                    IF COALESCE(o_numero_pedido, '') = '' THEN
                        v_dev = v_numero_pedido_generado;
                    ELSE
                        v_dev = COALESCE(v_dev, '') || ',' || v_numero_pedido_generado;
                    END IF;
                END IF;

            END IF;
        END LOOP;

    o_numero_pedido = CASE WHEN v_fact IS NOT NULL THEN 'Factura: ' || v_fact END;
    o_numero_pedido =
            COALESCE(o_numero_pedido, '') || CASE WHEN v_fact IS NOT NULL AND v_dev IS NOT NULL THEN ' - ' END;
    o_numero_pedido = COALESCE(o_numero_pedido, '') || CASE WHEN v_dev IS NOT NULL THEN ' Devolucion: ' || v_dev END;

    IF COALESCE(o_numero_pedido, '') = '' THEN
        RAISE EXCEPTION 'No hay nada pendiente por despachar para %', reg_cliente.nombre;
    END IF;

    -- Actualiza los ajustes
    UPDATE mercantil_tosi.ventas_pasa_semanal a
    SET procesado = TRUE
    WHERE TO_DATE(a.fecha, 'DD/MM/YYYY') BETWEEN p_fecha_inicial AND p_fecha_final
      AND NOT procesado;
END;
$function$
;
