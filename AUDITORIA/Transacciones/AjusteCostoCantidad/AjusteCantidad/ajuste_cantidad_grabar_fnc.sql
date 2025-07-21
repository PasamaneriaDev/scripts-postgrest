-- DROP FUNCTION control_inventarios.ajuste_cantidad_grabar_fnc(varchar, varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_cantidad_grabar_fnc(p_datajs character varying,
                                                                          p_referencia character varying,
                                                                          p_actualizar_ajuste boolean, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
    rec               RECORD;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Actualizo los que vengan con Secuecia
    WITH t
             AS
             (
                 UPDATE control_inventarios.ajustes a
                     SET cantidad_ajuste = x.cantidad_ajuste
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT, cantidad_ajuste DECIMAL, secuencia integer)
                     WHERE a.secuencia = x.secuencia/*a.documento = x.documento
                         AND a.item = x.item
                         AND x.secuencia <> 0*/
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
         , 'UPDATE v:\sbtpro\icdata\ICINVF01 ' ||
           'SET sqty = ' || t.cantidad_ajuste::VARCHAR || ' ' ||
           'WHERE secu_post = ' || t.secuencia::VARCHAR
    FROM t
    WHERE _interface_activo;

    -- Inserto los demas
    WITH t
             AS
             (
                 INSERT INTO control_inventarios.ajustes AS a
                     (documento, item, costo, costo_nuevo, cantidad_ajuste, tipo, cuenta_ajuste, cuenta, bodega,
                      ubicacion, creacion_usuario, anio_trimestre)
                     SELECT x.documento
                          , x.item
                          , i.costo_promedio
                          , i.costo_promedio
                          , x.cantidad_ajuste
                          , 'A'
                          , x.cuenta_ajuste
                          , x.cuenta
                          , x.bodega
                          , x.ubicacion
                          , p_usuario
                          , (CASE WHEN COALESCE(x.anio_trimestre, '') = '' THEN '0' ELSE x.anio_trimestre END)::numeric
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT,
                                                               cuenta_ajuste TEXT, cuenta TEXT,
                                                               cantidad_ajuste DECIMAL, bodega TEXT, ubicacion TEXT,
                                                               secuencia integer, anio_trimestre TEXT)
                              INNER JOIN
                          control_inventarios.items i ON x.item = i.item
                              INNER JOIN
                          control_inventarios.id_bodegas b ON i.bodega = b.bodega
                     WHERE x.secuencia = 0
                     RETURNING a.documento, a.item, a.costo, a.costo_nuevo, a.cantidad_ajuste
                         , a.tipo, a.cuenta_ajuste, a.cuenta, a.bodega, a.ubicacion, a.secuencia
                         , a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.anio_trimestre)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT t.creacion_usuario
         , 'AUDITORIA'
         , 'INSERT1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , 'INSERT INTO v:\sbtpro\icdata\ICINVF01 ' ||
           '(document, item, tcost, tcostn, sqty, ' ||
           ' type, ajacct, glacnt, loctid, qstore, Secu_post, ' ||
           ' adduser, descrip, stkumid, adddate, addtime, anio_trime) VALUES(' ||
           '[' || t.documento || '], [' || t.item || '], ' || t.costo::VARCHAR || ', ' || t.costo_nuevo::VARCHAR ||
           ', ' || t.cantidad_ajuste::VARCHAR || ', [' ||
           t.tipo || '], [' || t.cuenta_ajuste || '], [' || t.cuenta || '], [' || t.bodega || '], [' || t.ubicacion ||
           '], ' || t.secuencia::varchar || ', [' ||
           t.creacion_usuario || '], [' || i.descripcion || '], [' || i.unidad_medida || '], {^' ||
           TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD') || '}, [' || t.creacion_hora || '], ' || t.anio_trimestre || ')'
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;

    IF p_actualizar_ajuste THEN

        SELECT x.documento
        INTO rec
        FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT)
        LIMIT 1;
        PERFORM control_inventarios.ajuste_cantidad_actualizacion_inventario(rec.documento, 'A', p_referencia,
                                                                             p_usuario);

    END IF;
END ;
$function$
;
