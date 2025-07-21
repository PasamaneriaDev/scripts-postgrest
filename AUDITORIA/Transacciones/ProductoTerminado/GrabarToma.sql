-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_terminados_grabar_fnc(p_datajs character varying, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    WITH t
             AS
             (
                 UPDATE control_inventarios.ajustes a
                     SET cantidad_ajuste = TRUNC(x.cantidad_ajuste, i.numero_decimales::integer)
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (cantidad_ajuste DECIMAL, secuencia integer, item TEXT)
                         JOIN control_inventarios.items i ON x.item = i.item
                     WHERE a.secuencia = x.secuencia
                     RETURNING a.cantidad_ajuste, a.secuencia)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT p_usuario
         , 'AUDITORIA'
         , 'UPDATE1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , FORMAT(
            'UPDATE v:\sbtpro\icdata\ICINVF01 ' ||
            'SET sqty = %s ' ||
            'WHERE secu_post = %s',
            t.cantidad_ajuste::VARCHAR, t.secuencia::VARCHAR)
    FROM t
    WHERE _interface_activo;

    -- Inserto los demas
    WITH t
             AS
             (
                 INSERT INTO control_inventarios.ajustes AS a
                     (documento, item, costo,
                      costo_nuevo, orden,
                      cantidad_ajuste, bodega, ubicacion, tipo, creacion_usuario)
                     SELECT LPAD(x.documento, 10, '0')
                          , x.item
                          , i.costo_promedio
                          , i.costo_promedio
                          , x.codigo_barras
                          , TRUNC(x.cantidad_ajuste, i.numero_decimales::integer)
                          , x.bodega
                          , x.ubicacion
                          , 'T'
                          , p_usuario
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT, codigo_barras TEXT,
                                                               cantidad_ajuste DECIMAL, bodega TEXT, ubicacion TEXT,
                                                               secuencia integer)
                              JOIN control_inventarios.items i ON x.item = i.item
                     WHERE COALESCE(x.secuencia, 0) = 0
                     RETURNING a.documento, a.item, a.costo, a.costo_nuevo, a.orden, a.cantidad_ajuste, a.bodega,
                         a.ubicacion, a.tipo, a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.secuencia)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT t.creacion_usuario
         , 'AUDITORIA'
         , 'INSERT1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , FORMAT(
            'INSERT INTO v:\sbtpro\icdata\ICINVF01 ' ||
            '(document, item, descrip, stkumid, tcost, ' ||
            ' tcostn, orden, sqty, loctid, qstore, ' ||
            ' type, adddate, addtime, adduser, secu_post) ' ||
            'VALUES([%s], [%s], [%s], [%s], %s, ' ||
            '       %s, [%s], %s, [%s], [%s], ' ||
            '       [%s], {^%s}, [%s], [%s], %s)',
            t.documento, t.item, i.descripcion, i.unidad_medida, t.costo::VARCHAR,
            t.costo_nuevo::VARCHAR, t.orden, t.cantidad_ajuste::VARCHAR, t.bodega, t.ubicacion,
            t.tipo, TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD'), t.creacion_hora, t.creacion_usuario, t.secuencia::varchar)
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;

END ;
$function$
;
