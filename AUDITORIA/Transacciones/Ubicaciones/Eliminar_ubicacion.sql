-- DROP FUNCTION control_inventarios.ubicacion_eliminar(in varchar, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION control_inventarios.ubicacion_eliminar(p_bodega character varying, p_ubicacion character varying, p_usuario character varying, OUT respuesta text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_existencias     numeric;
    _interface_activo boolean;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Verificar que no sea una ubicacion con existencias
    SELECT SUM(u.existencia + u.transito + u.comprometido_despacho)
    INTO v_existencias
    FROM control_inventarios.ubicaciones u
    WHERE u.bodega = p_bodega
      AND u.ubicacion = p_ubicacion;

    IF v_existencias <> 0 THEN
        RAISE EXCEPTION 'La ubicacion tiene existencias';
    END IF;

    DELETE
    FROM control_inventarios.ID_Ubicaciones
    WHERE bodega = p_bodega
      AND ubicacion = p_ubicacion;

    -- Graba la INTERFAZ
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'LISTA_MATERIALES',
           'DELETE',
           'iclocs01',
           p_usuario,
           'v:\sbtpro\ICDATA\',
           '',
           'DELETE FROM v:\sbtpro\icdata\iclocs01 WHERE loctid = ''' || rpad(p_bodega, 3, ' ') || ''' AND store = ''' ||
           rpad(p_ubicacion, 4, ' ') || ''''
    WHERE _interface_activo;

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
