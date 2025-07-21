-- DROP FUNCTION control_inventarios.transferencias_revision_errores_recep_fnc(varchar, text);

CREATE OR REPLACE FUNCTION control_inventarios.transferencias_revision_errores_recep_fnc(p_datajs character varying, p_usuario text)
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
                 UPDATE control_inventarios.transferencia_errores a
                     SET revisado = TRUE
                     FROM JSON_TO_RECORDSET(p_datajs::json) x (secuencia integer)
                     WHERE a.secuencia = x.secuencia
                     RETURNING a.transaccion, a.bodega, a.item)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT p_usuario
         , 'AUDITORIA'
         , 'UPDATE1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'Icerro01'
         , ''
         , 'UPDATE v:\sbtpro\icdata\Icerro01 ' ||
           'SET revisado = .t. ' ||
           'WHERE ttranno = [' || RPAD(t.transaccion, 10, ' ') || '] ' ||
           'AND item = [' || RPAD(t.item, 15, ' ') || '] ' ||
           'AND loctid = [' || RPAD(t.bodega, 3, ' ') || '] '
    FROM t
    WHERE _interface_activo;

END ;
$function$
;
