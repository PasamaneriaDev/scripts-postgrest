CREATE OR REPLACE FUNCTION cuentas_cobrar.guias_remision_manual(p_datajs text,
                                                                p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo BOOLEAN = TRUE;
    v_numero_guia     varchar;
    p_datajs_updated  jsonb;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    p_datajs_updated = p_datajs::jsonb || '{"tipo_documento": "M"}'::jsonb;

    SELECT o_numero_guia
    INTO v_numero_guia
    FROM cuentas_cobrar.guias_remision_nueva(p_datajs_updated::text,p_usuario);

    WITH t AS (
        INSERT INTO cuentas_cobrar.detalle_guia_manual AS a
            (numero_guia, item, descripcion, cantidad)
            SELECT v_numero_guia,
                   a.item,
                   a.descripcion,
                   a.cantidad
            FROM JSON_TO_RECORDSET(p_datajs::json -> 'detalles') a (item text, descripcion text, cantidad numeric)
            RETURNING a.numero_guia, a.item, a.descripcion, a.cantidad)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'INSERT1',
           'ARDETGUIM',
           p_usuario,
           'V:\SBTPRO\ARDATA\ ',
           '',
           FORMAT('INSERT INTO V:\SBTPRO\ARDATA\ARDETGUIM ' ||
                  '(refnum_gui, item, descripcio, cantidad) ' ||
                  'VALUES([%s], [%s], [%s], %s)',
                  t.numero_guia, t.item, t.descripcion, t.cantidad)
    FROM t
    WHERE _interface_activo;
END;

$function$
;


