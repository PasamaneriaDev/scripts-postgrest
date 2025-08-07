CREATE OR REPLACE FUNCTION cuentas_cobrar.cliente_update_varios(p_datajs text,
                                                                p_usuario text)
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

    WITH t AS (
        UPDATE cuentas_cobrar.clientes AS c
            SET cedula_ruc = (p_datajs::json ->> 'cedula_ruc'),
                nombre = (p_datajs::json ->> 'nombre'),
                telefono1 = (p_datajs::json ->> 'telefono1'),
                direccion = (p_datajs::json ->> 'direccion')
            WHERE codigo = 'VARIOS'
            RETURNING c.codigo, c.cedula_ruc, c.nombre, c.telefono1, c.direccion)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'UPDATE1',
           'Arcust01',
           p_usuario,
           'V:\sbtpro\ARDATA',
           '',
           FORMAT('UPDATE V:\sbtpro\ARDATA\Arcust01 ' ||
                  'set ciruc = [%s], ' ||
                  '    address1 = [%s], ' ||
                  '    company = [%s], ' ||
                  '    phone = [%s]' ||
                  'Where custno = [%s] ',
                  t.cedula_ruc, t.direccion, t.nombre, t.telefono1, t.codigo)
    FROM t
    WHERE _interface_activo;

END;
$function$
;


