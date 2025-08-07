-- drop function cuentas_cobrar.guias_remision_actualiza_autorizacion(varchar);

CREATE OR REPLACE FUNCTION cuentas_cobrar.facturas_actualiza_autorizacion_from_guias(p_bod_entorno varchar)
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
        UPDATE cuentas_cobrar.facturas_cabecera c
            SET numero_autorizacion = t.numero_autorizacion
            FROM (SELECT g.referencia, g.tipo_documento, g.numero_autorizacion
                  FROM cuentas_cobrar.guias_remision g
                  WHERE TRIM(COALESCE(g.impreso, '')) = ''
                    AND (g.bodega = p_bod_entorno OR
                         (p_bod_entorno = '001' AND g.bodega = '023'))
                    AND (g.tipo_documento = 'F' OR g.tipo_documento = 'D')) t
            WHERE c.referencia = t.referencia
                AND COALESCE(c.numero_autorizacion, '') = ''
            RETURNING c.referencia, c.numero_autorizacion)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'UPDATE',
           'ARMAST01',
           '',
           'V:\SBTPRO\ARDATA\ ',
           '',
           FORMAT('REPLACE ' ||
                  '  num_autori WITH [%s] ' ||
                  'FOR invno = [%s] IN ARMAST01',
                  x.numero_autorizacion, x.referencia)
    FROM x
    WHERE _interface_activo;
END;
$function$
;
