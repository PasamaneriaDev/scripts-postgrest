CREATE OR REPLACE FUNCTION cuentas_cobrar.guias_remision_transferencia(p_datajs text,
                                                                       p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo BOOLEAN = TRUE;
    v_numero_guia     varchar;
    v_factura         varchar = '';
    p_datajs_updated  jsonb;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    p_datajs_updated = p_datajs::jsonb;

    IF p_datajs::json ->> 'tipo_documento' = 'D' THEN
        SELECT factura
        INTO v_factura
        FROM cuentas_cobrar.facturas_cabecera
        WHERE referencia = (p_datajs::json ->> 'referencia');

        p_datajs_updated = p_datajs_updated || ('{"factura": "' || coalesce(v_factura, '') || '"}')::jsonb;

        IF NOT found THEN
            RAISE EXCEPTION 'No existe factura para la referencia %', (p_datajs::json ->> 'referencia');
        END IF;
    END IF;

    SELECT o_numero_guia
    INTO v_numero_guia
    FROM cuentas_cobrar.guias_remision_nueva(p_datajs_updated::text,p_usuario);

END;
$function$
;


