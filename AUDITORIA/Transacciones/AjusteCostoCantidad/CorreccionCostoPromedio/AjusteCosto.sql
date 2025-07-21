-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_costo_grabar_fnc(p_datajs character varying,
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

    WITH t
             AS
             (
                 INSERT INTO control_inventarios.ajustes AS a
                     (documento, item, costo, costo_nuevo, cantidad_ajuste, tipo, cuenta_ajuste, cuenta, bodega,
                      ubicacion, creacion_usuario)
                     SELECT x.documento
                          , x.item
                          , i.costo_promedio
                          , x.costo_nuevo
                          , i.existencia
                          , x.tipo
                          , x.cuenta_ajuste
                          , x.cuenta
                          , i.bodega
                          , b.ubicacion_default
                          , p_usuario
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, item TEXT,
                                                               costo_nuevo DECIMAL, tipo TEXT,
                                                               cuenta_ajuste TEXT, cuenta TEXT)
                              INNER JOIN
                          control_inventarios.items i ON x.item = i.item
                              INNER JOIN
                          control_inventarios.id_bodegas b ON i.bodega = b.bodega
                     RETURNING a.documento, a.item, a.costo, a.costo_nuevo, a.cantidad_ajuste
                         , a.tipo, a.cuenta_ajuste, a.cuenta, a.bodega, a.ubicacion
                         , a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.secuencia)
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
           ' adduser, descrip, stkumid, adddate, addtime) VALUES(' ||
           '[' || t.documento || '], [' || t.item || '], ' || t.costo::VARCHAR || ', ' || t.costo_nuevo::VARCHAR ||
           ', ' || t.cantidad_ajuste::VARCHAR || ', [' ||
           t.tipo || '], [' || t.cuenta_ajuste || '], [' || t.cuenta || '], [' || t.bodega || '], [' || t.ubicacion ||
           '], ' || t.secuencia || ', [' ||
           t.creacion_usuario || '], [' || i.descripcion || '], [' || i.unidad_medida || '], {^' ||
           TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD') || '}, [' || t.creacion_hora || '])'
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;

    IF p_actualizar_ajuste THEN

        SELECT x.documento, x.tipo, x.referencia
        INTO rec
        FROM JSON_TO_RECORDSET(p_datajs::json) x (documento TEXT, tipo TEXT, referencia TEXT)
        LIMIT 1;
        PERFORM control_inventarios.ajuste_costo_actualizacion_inventario(rec.documento, rec.tipo, rec.referencia,
                                                                          p_usuario);

    END IF;
END ;
$function$
;
