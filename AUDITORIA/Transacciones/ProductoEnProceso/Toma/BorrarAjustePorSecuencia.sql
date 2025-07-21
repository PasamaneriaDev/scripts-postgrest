-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_eliminar_por_secuencia(p_secuencia integer, p_usuario text)
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

    WITH x AS (
        DELETE FROM control_inventarios.ajustes a
            WHERE a.secuencia = p_secuencia
               RETURNING a.secuencia)
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
           'Where secu_post = ' || x.secuencia::VARCHAR
    FROM x
    WHERE _interface_activo;

END ;
$function$
;
