CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_agregar_item(p_numero_pedido varchar, p_item varchar,
                                                              p_descripcion varchar, p_cantidad numeric,
                                                              p_porcentaje_descuento numeric, p_usuario varchar)
    RETURNS boolean
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo   boolean = TRUE;
    new_monto_iva       numeric;
    new_monto_pendiente numeric;
    v_cliente           varchar;
    rec_det_ped         ordenes_venta.pedidos_detalle;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');
    -- Validar
    IF EXISTS(SELECT 'X'
              FROM ordenes_venta.pedidos_detalle pd
              WHERE pd.numero_pedido = p_numero_pedido
                AND pd.item = p_item
                AND pd.porcentaje_descuento = p_porcentaje_descuento) THEN
        RAISE EXCEPTION 'Item ya existe en el detalle.';
    END IF;

    -- Agregar Item

    INSERT INTO ordenes_venta.pedidos_detalle
    (numero_pedido, tipo_pedido, cliente, item, descripcion, porcentaje_descuento, porcentaje_iva, costo, precio,
     cantidad_pendiente, subtotal, fecha_original_pedido,
     vendedor, codigo_venta, codigo_inventario, precio_manual, es_stock, tiene_iva,
     bodega, creacion_usuario, creacion_fecha, creacion_hora, tipo_precio,
     cantidad_original, fecha_pedido, numero_pedido_vendedor,
     color_comercial, precio_catalogo, cliente_catalogo, territorio,
     numero_linea, existencia_999)
    SELECT pc.numero_pedido,
           pc.tipo_pedido,
           pc.cliente,
           i.item,
           p_descripcion,
           p_porcentaje_descuento,
           pc.porcentaje_iva,
           i.costo_promedio,
           p.precio,
           p_cantidad,
           p.precio * p_cantidad * (1 - p_porcentaje_descuento / 100),
           pc.fecha_pedido,
           pc.vendedor,
           pc.codigo_venta,
           'PRT',
           'N',
           i.es_stock,
           i.tiene_iva,
           pc.bodega,
           p_usuario,
           CURRENT_DATE,
           LOCALTIME(0),
           pc.tipo_precio,
           p_cantidad,
           CURRENT_DATE,
           '',
           '0',
           0,
           '',
           pc.territorio,
           0,
           (SELECT CASE
                       WHEN LEFT(r.tipo_comision, 1) = 'Q'
                           THEN (SELECT SUM(COALESCE(b.existencia, 0))
                                 FROM control_inventarios.bodegas b
                                 WHERE b.item = i.item
                                   AND bodega IN ('999', '100'))
                       ELSE (SELECT SUM(COALESCE(b.existencia, 0))
                             FROM control_inventarios.bodegas b
                             WHERE b.item = i.item
                               AND b.bodega IN ('999'))
                       END --as LV_EXISTENCIA
            FROM sistema.reglas r
            WHERE r.codigo = pc.vendedor
              AND r.regla = 'SLSPERS') AS existencia_999
    FROM ordenes_venta.pedidos_cabecera pc
             JOIN control_inventarios.items i ON i.item = p_item
             JOIN control_inventarios.precios p ON i.item = p.item AND tipo = pc.tipo_precio
    WHERE pc.numero_pedido = p_numero_pedido
    RETURNING pedidos_detalle.*
        INTO rec_det_ped;

    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, directorio, usuarios, buscar, sql)
    SELECT 'ORDENES DE VENTA'
         , 'INSERT1'
         , 'SOTRAN01'
         , 'V:\SBTPRO\SODATA\ '
         , p_usuario
         , ''
         , 'Insert Into V:\SBTPRO\SODATA\SOTRAN01 (' ||
           'sono, custno, item, descrip, disc' ||
           ', taxrate, secu_post, cost, price, qtyord' ||
           ', qtyshp, extprice, ordate, salesmn, glsale' ||
           ', glasst, macode, stkcode, taxable, sostat' ||
           ', terr, sotype, loctid, lineno' ||
           ', adduser, adddate, addtime, pricecode' ||
           ', qtyord_o, fecped, sonopalm, cat_color, cat_ruccli' ||
           ', cat_precio, recargo, existen999) Values ([' ||
           COALESCE(RIGHT('          ' || rec_det_ped.numero_pedido, 10), '') || '], [' || rec_det_ped.cliente ||
           '], [' || rec_det_ped.item || '], [' ||
           COALESCE(p_descripcion, '') || '], ' || COALESCE(rec_det_ped.porcentaje_descuento::VARCHAR, '') || ', ' ||
           COALESCE(rec_det_ped.porcentaje_iva::VARCHAR, '') || ', ' || COALESCE(rec_det_ped.secuencia::VARCHAR, '') ||
           ', ' || COALESCE(rec_det_ped.costo::VARCHAR, '') || ', ' ||
           COALESCE(rec_det_ped.precio::VARCHAR, '') || ', ' || COALESCE(rec_det_ped.cantidad_pendiente::VARCHAR, '') ||
           ', ' || COALESCE(rec_det_ped.cantidad_despachada::varchar, '') || ', ' ||
           COALESCE(rec_det_ped.subtotal::VARCHAR, '') || ', [' ||
           COALESCE(TO_CHAR(rec_det_ped.fecha_original_pedido, 'MM/DD/YYYY'), '') || '], [' ||
           COALESCE(rec_det_ped.vendedor, '') || '], [' || COALESCE(rec_det_ped.codigo_venta, '') ||
           '], [' || COALESCE(rec_det_ped.codigo_inventario, '') || '], [' || COALESCE(rec_det_ped.precio_manual, '') ||
           '], [' || COALESCE(CASE WHEN rec_det_ped.es_stock THEN 'Y' ELSE 'N' END, '') || '], [' ||
           COALESCE(CASE WHEN rec_det_ped.tiene_iva THEN 'Y' ELSE 'N' END, '') || '], [' || rec_det_ped.estado ||
           '], [' || COALESCE(rec_det_ped.territorio, '') || '], [' || COALESCE(rec_det_ped.tipo_pedido, '') ||
           '], [' ||
           COALESCE(rec_det_ped.bodega, '') || '], ' || COALESCE(rec_det_ped.numero_linea::varchar, '') || ', [' ||
           COALESCE(rec_det_ped.creacion_usuario, '') || '], {^' ||
           COALESCE(TO_CHAR(rec_det_ped.creacion_fecha, 'YYYY-MM-DD'), '') ||
           '}, [' || COALESCE(rec_det_ped.creacion_hora, '') ||
           '], [' || COALESCE(rec_det_ped.tipo_precio, '') || '], ' ||
           COALESCE(rec_det_ped.cantidad_original::VARCHAR, '') || ', [' ||
           COALESCE(TO_CHAR(rec_det_ped.fecha_pedido, 'MM/DD/YYYY'), '') ||
           '], [' || COALESCE(rec_det_ped.numero_pedido_vendedor, '') || '], [' ||
           rec_det_ped.color_comercial || '], [' || rec_det_ped.cliente_catalogo || '], ' ||
           COALESCE(rec_det_ped.precio_catalogo::VARCHAR, '') || ', ' ||
           COALESCE(rec_det_ped.porcentaje_recargo_hilos::VARCHAR, '') ||
           ', ' || COALESCE(rec_det_ped.existencia_999::VARCHAR, '') || ')'
    WHERE _interface_activo;

    -- INSERTA EN LA BITACORA
    INSERT INTO ordenes_venta.pedidos_detalle_bitacora(numero_pedido, item, secuencia, cliente,
                                                       cliente_catalogo, color_comercial,
                                                       porcentaje_descuento_anterior,
                                                       porcentaje_descuento_nuevo, precio_anterior,
                                                       precio_nuevo,
                                                       descripcion_anterior, descripcion_nueva,
                                                       creacion_usuario, creacion_fecha)

    VALUES (p_numero_pedido, rec_det_ped.item, rec_det_ped.secuencia, rec_det_ped.cliente, rec_det_ped.cliente_catalogo,
            rec_det_ped.color_comercial,
            rec_det_ped.porcentaje_descuento, rec_det_ped.porcentaje_descuento, rec_det_ped.precio,
            rec_det_ped.precio, rec_det_ped.descripcion, 'NUEVO ITEM AGREGADO AL PEDIDO', rec_det_ped.creacion_usuario,
            CURRENT_TIMESTAMP);

    /********************************************************************************************************/
    -- Calcular el monto del IVA y el monto pendiente
    SELECT SUM(pd.subtotal * pd.porcentaje_iva / 100)                 AS monto_iva,
           SUM(pd.subtotal + (pd.subtotal * pd.porcentaje_iva / 100)) AS monto_pendiente
    INTO new_monto_iva, new_monto_pendiente
    FROM ordenes_venta.pedidos_detalle pd
    WHERE pd.numero_pedido = p_numero_pedido
      AND COALESCE(pd.estado, '') = ''
      AND pd.cantidad_pendiente > 0
      AND pd.tipo_pedido <> 'B'
      AND LEFT(pd.cliente, 3) NOT SIMILAR TO '999|991';

    -- ACTUALIZACIÓN en la Cabecera del Pedido
    WITH cte AS (
        UPDATE ordenes_venta.pedidos_cabecera t1
            SET monto_iva = new_monto_iva,
                monto_pendiente = new_monto_pendiente
            WHERE t1.numero_pedido = p_numero_pedido
            RETURNING t1.monto_iva, t1.monto_pendiente)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'ORDENES DE VENTA',
           'UPDATE',
           'Somast01',
           p_usuario,
           'V:\sbtpro\SODATA\',
           '=SEEK([' || LPAD(p_numero_pedido::varchar, 10, ' ') || '],[Somast01],[sono])',
           'REPLACE tax WITH ' || CAST((cte.monto_iva) AS VARCHAR) ||
           ', ordamt WITH ' || CAST(cte.monto_pendiente AS VARCHAR)
    FROM cte
    WHERE _interface_activo;

    /********************************************************************************************************/
    -- Obtener el cliente
    SELECT pc.cliente
    INTO v_cliente
    FROM ordenes_venta.pedidos_cabecera pc
    WHERE numero_pedido = p_numero_pedido;

    -- ACTUALIZACIÓN del Saldo del cliente
    WITH cte AS (
        UPDATE cuentas_cobrar.clientes t1
            SET pedidos = (SELECT SUM(t2.monto_pendiente)
                           FROM ordenes_venta.pedidos_cabecera t2
                           WHERE t1.codigo = t2.cliente
                             AND t2.monto_pendiente > 0
                             AND COALESCE(t2.estado, '') = '')
            WHERE t1.codigo = v_cliente
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
           'set onorder = ' || COALESCE(cte.pedidos, 0)::varchar || ' ' ||
           'Where custno = [' || v_cliente || '] '
    FROM cte
    WHERE _interface_activo;

    RETURN TRUE;
END ;
$function$