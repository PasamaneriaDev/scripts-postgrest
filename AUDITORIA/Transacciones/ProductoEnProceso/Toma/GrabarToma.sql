-- DROP FUNCTION control_inventarios.ajuste_toma_produccion_grabar_fnc(varchar, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_produccion_grabar_fnc(p_datajs character varying, p_usuario text)
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

    -- Al momento no esta programado para que se modifique valores en la pantalla
    -- Solo Agregar y Eliminar (Se hace ahi mismo)
    -- WITH t
    --          AS
    --          (
    --              UPDATE control_inventarios.ajustes a
    --                  SET cantidad = x.cantidad,
    --                      conos = x.conos,
    --                      tara = x.tara,
    --                      cajon = x.cajon,
    --                      constante = x.constante,
    --                      cantidad_ajuste = x.cantidad_ajuste
    --                  FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, cantidad decimal, conos integer,
    --                                                            tara decimal, cajon decimal, constante decimal,
    --                                                            cantidad_ajuste DECIMAL, secuencia integer)
    --                  WHERE a.documento = LPAD(x.documento, 10, '0')
    --                      AND a.secuencia = x.secuencia
    --                  RETURNING a.cantidad, a.conos, a.tara, a.cajon,
    --                      a.constante, a.cantidad_ajuste, a.documento, a.secuencia, a.item)
    -- INSERT
    -- INTO sistema.interface
    --     (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    -- SELECT p_usuario
    --      , 'AUDITORIA'
    --      , 'UPDATE1'
    --      , 'V:\SBTPRO\ICDATA\ '
    --      , 'ICINVF01'
    --      , ''
    --      , FORMAT(
    --         'UPDATE v:\sbtpro\icdata\ICINVF01 ' ||
    --         'SET cantidad  = %s ' ||
    --         '    conos     = %s ' ||
    --         '    tara      = %s ' ||
    --         '    cajon     = %s ' ||
    --         '    constante = %s ' ||
    --         '    sqty      = %s ' ||
    --         'WHERE document = [%s] AND item = [%s]',
    --         t.cantidad::VARCHAR, t.conos::VARCHAR, t.tara::VARCHAR, t.cajon::VARCHAR, t.constante::VARCHAR,
    --         t.cantidad_ajuste::VARCHAR, t.documento, RPAD(t.item, 15, ' '))
    -- FROM t
    -- WHERE _interface_activo;

    -- Inserto los demas
    WITH t
             AS
             (
                 INSERT INTO control_inventarios.ajustes AS a
                     (documento, item, costo, costo_nuevo, orden, cantidad, conos, tara, cajon, constante,
                      muestra, cantidad_ajuste, bodega, ubicacion, tipo, creacion_usuario)
                     SELECT LPAD(x.documento, 10, '0')
                          , x.item
                          , x.costo
                          , x.costo_nuevo
                          , x.orden
                          , x.cantidad
                          , x.conos
                          , x.tara
                          , x.cajon
                          , x.constante
                          , NULLIF(x.muestra, '')
                          , x.cantidad_ajuste
                          , x.bodega
                          , x.ubicacion
                          , 'T'
                          , p_usuario
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT, costo DECIMAL,
                                                               costo_nuevo DECIMAL, orden TEXT, cantidad DECIMAL,
                                                               conos integer, tara DECIMAL, cajon DECIMAL,
                                                               constante DECIMAL, muestra Text,
                                                               cantidad_ajuste DECIMAL, bodega TEXT, ubicacion TEXT,
                                                               secuencia integer)
                     WHERE COALESCE(x.secuencia, 0) = 0
                     RETURNING a.documento, a.item, a.costo, a.costo_nuevo, a.orden, a.cantidad, a.conos, a.tara,
                         a.cajon, a.constante, a.muestra, a.cantidad_ajuste, a.bodega, a.ubicacion, a.tipo,
                         a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.secuencia)
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
            ' tcostn, orden, cantidad, conos, tara, ' ||
            ' cajon, constante, sqty, loctid, qstore, ' ||
            ' type, muestra, adddate, addtime, adduser, ' ||
            ' secu_post) ' ||
            'VALUES([%s], [%s], [%s], [%s], %s, ' ||
            '       %s, [%s], %s, %s, %s, ' ||
            '       %s, %s, %s, [%s], [%s], ' ||
            '       [%s], %s, {^%s}, [%s], [%s],' ||
            '       %s)',
            t.documento, t.item, i.descripcion, i.unidad_medida, t.costo::VARCHAR,
            t.costo_nuevo::VARCHAR, t.orden, t.cantidad::varchar, t.conos::varchar, t.tara::varchar,
            t.cajon, t.constante::varchar, t.cantidad_ajuste::VARCHAR, t.bodega, t.ubicacion,
            t.tipo, memo_to_string(coalesce(t.muestra, '')), TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD'), t.creacion_hora,
            t.creacion_usuario,
            t.secuencia::varchar)
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;

END ;
$function$
;
