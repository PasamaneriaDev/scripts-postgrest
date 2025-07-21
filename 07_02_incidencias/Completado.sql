-- DROP FUNCTION puntos_venta.incidencias_cambiar_estado_noautorizado(in int4, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_cambiar_estado_completado(p_numero_incidencia integer,
                                                                              p_usuario character varying,
                                                                              OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha)
    VALUES (p_numero_incidencia, 'COMPLETO', p_usuario, CURRENT_TIMESTAMP);

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
