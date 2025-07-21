CREATE OR REPLACE FUNCTION auditoria.papeletas_obtiene_maximo()
    RETURNS numeric
    LANGUAGE plpgsql
AS
$function$
DECLARE
    papeleta_maxima numeric = 1;
BEGIN
    SELECT numero
    INTO papeleta_maxima
    FROM sistema.parametros p
    WHERE modulo_id = 'AUDITORIA'
      AND codigo = 'PAPELETAS_INVENTARIO_PROCESO';

    RETURN papeleta_maxima;
END;
$function$
;
