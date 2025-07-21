-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_consignaciones_grabar_fnc(p_datajs character varying, p_bodega text, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo   BOOLEAN = TRUE;
    v_count_equal       INTEGER;
    v_count_diferent    INTEGER;
    v_ubicacion_default TEXT;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- VALIDACION QUE PIDIO INGENIERO MOGROVEJO
    -- IF p_bodega = '162' THEN
    --     -- si el item inicia con BA, 2828 O 2868, no se permite que en la lista tenga items diferentes
    --     -- si no tiene los items señalados, se permite el resto
    --     SELECT COUNT(x.item)
    --     INTO v_count_equal
    --     FROM JSON_TO_RECORDSET(p_datajs::json) x (item TEXT)
    --     WHERE x.item LIKE 'BA%'
    --        OR x.item LIKE '2828%'
    --        OR x.item LIKE '2868%';

    --     SELECT COUNT(x.item)
    --     INTO v_count_diferent
    --     FROM JSON_TO_RECORDSET(p_datajs::json) x (item text)
    --     WHERE x.item NOT LIKE 'BA%'
    --       AND x.item NOT LIKE '2828%'
    --       AND x.item NOT LIKE '2868%';

    --     IF v_count_equal > 0 AND v_count_diferent > 0 THEN
    --         RAISE EXCEPTION 'No se permite mezclar los items items con descuento con los demas.';
    --     END IF;
    -- END IF;

    -- Busca la ubicacion por defecto
    SELECT ib.ubicacion_default
    INTO v_ubicacion_default
    FROM control_inventarios.id_bodegas ib
    WHERE ib.bodega = p_bodega;

    -- Inserto los demas
    WITH t
             AS
             (
                 INSERT INTO control_inventarios.ajustes AS a
                     (documento, item, costo, costo_nuevo,
                      cantidad_ajuste, bodega, ubicacion, tipo, creacion_usuario)
                     SELECT LPAD(x.documento, 10, '0')
                          , x.item
                          , i.costo_promedio
                          , i.costo_promedio
                          , TRUNC(x.cantidad_ajuste, i.numero_decimales::integer)
                          , p_bodega
                          , v_ubicacion_default
                          , 'T'
                          , p_usuario
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT, cantidad_ajuste DECIMAL,
                                                               secuencia integer)
                              JOIN control_inventarios.items i ON x.item = i.item
                     WHERE COALESCE(x.secuencia, 0) = 0
                     RETURNING a.documento, a.item, a.costo, a.costo_nuevo, a.orden, a.cantidad_ajuste, a.bodega,
                         a.ubicacion, a.tipo, a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.secuencia)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT t.creacion_usuario
         , 'ORDENES DE VENTA'
         , 'INSERT1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , FORMAT(
            'INSERT INTO v:\sbtpro\icdata\ICINVF01 ' ||
            '(document, item, descrip, stkumid, tcost, ' ||
            ' tcostn, sqty, loctid, qstore, ' ||
            ' type, adddate, addtime, adduser, secu_post) ' ||
            'VALUES([%s], [%s], [%s], [%s], %s, ' ||
            '       %s, %s, [%s], [%s], ' ||
            '       [%s], {^%s}, [%s], [%s], %s)',
            t.documento, t.item, i.descripcion, i.unidad_medida, t.costo::VARCHAR,
            t.costo_nuevo::VARCHAR, t.cantidad_ajuste::VARCHAR, RPAD(t.bodega, 3, ' '), t.ubicacion,
            t.tipo, TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD'), t.creacion_hora, t.creacion_usuario, t.secuencia::varchar)
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;
END ;
$function$
;
