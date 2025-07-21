CREATE OR REPLACE FUNCTION auditoria.papeleta_cambiar_bloqueo(p_numero_papeleta varchar,
                                                              p_bloqueado_por varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    UPDATE auditoria.papeletas_inventario
    SET bloqueado_por = COALESCE(p_bloqueado_por, '')
    WHERE numero_papeleta = p_numero_papeleta;
END;
$function$;