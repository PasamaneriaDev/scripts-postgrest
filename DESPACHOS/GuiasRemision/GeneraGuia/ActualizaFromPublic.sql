-- drop function cuentas_cobrar.guias_remision_actualiza_autorizacion_from_public();

CREATE OR REPLACE FUNCTION cuentas_cobrar.facturas_actualiza_autorizacion_from_public()
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

    -- Pendiente hasta que se agrege la referencia interna a public.cc_elec_cabecera
    IF FALSE THEN
        WITH t AS (
            UPDATE cuentas_cobrar.facturas_cabecera c
                SET ambiente_sri = 'PRODUCCION',
                    numero_autorizacion = e.numero_autorizacion,
                    fecha_autorizacion = e.fecha_autorizacion::DATE,
                    hora_autorizacion = TO_CHAR(e.fecha_autorizacion::TIMESTAMP, 'HH24:MI:SS')
                FROM (SELECT CONCAT(establecimiento, puntoemision, secuencial) AS factura,
                             numero_autorizacion,
                             fecha_autorizacion
                      FROM public.cc_elec_cabecera
                      WHERE enviado_sri = 'AUTORIZADO'
                        AND documento = '01') e
                WHERE c.factura = e.factura
                    AND c.numero_autorizacion = ''
                RETURNING c.*)
        INSERT
        INTO sistema.interface (modulo, proceso, tabla, usuarios, directorio, buscar, SQL)
        SELECT 'DESPACHOS',
               'UPDATE',
               'ARMAST01',
               '',
               'V:\SBTPRO\ARDATA\ ',
               '',
               FORMAT('REPLACE ' ||
                      '  ambien_sri WITH [%s], ' ||
                      '  num_autori WITH [%s], ' ||
                      '  fec_autori WITH {^%s}, ' ||
                      '  hora_autorizacion WITH [%s] ' ||
                      'FOR invno = [%s] IN ARMAST01',
                      t.ambiente_sri, t.numero_autorizacion, TO_CHAR(t.fecha_autorizacion, 'YYYY-MM-DD'),
                      t.numero_autorizacion, t.referencia)
        FROM t
        WHERE _interface_activo;
    END IF;
END ;
$function$
;
