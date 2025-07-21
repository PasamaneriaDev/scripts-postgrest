CREATE OR REPLACE FUNCTION cuentas_pagar.validacion_autorizacion_tipo_comp(p_autorizacion varchar, p_tipo_comprobante int)
    RETURNS boolean AS
$$
DECLARE
BEGIN
    IF LENGTH(p_autorizacion) < 49 THEN
        RETURN TRUE;
    END IF;

    IF SUBSTRING(p_autorizacion, 9, 2) <> TO_CHAR(p_tipo_comprobante, 'FM00') THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;