-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_eliminar_por_documento(p_documento varchar, p_usuario text)
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


    DELETE
    FROM control_inventarios.ajustes a
    WHERE a.documento = LPAD(p_documento, 10, '0');

    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT p_usuario,
           'AUDITORIA',
           'DELETE1',
           'V:\SBTPRO\ICDATA\',
           'ICINVF01',
           '',
           'DELETE FROM V:\SBTPRO\ICDATA\ICINVF01 ' ||
           'Where document = [' || LPAD(p_documento, 10, '0') || ']'
    WHERE _interface_activo;

END ;
$function$
;
