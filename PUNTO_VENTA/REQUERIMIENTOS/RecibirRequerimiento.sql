-- DROP FUNCTION puntos_venta.requerimientos_cambiar_estado_autorizado(integer, varchar, varchar, boolean);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_cambiar_estado_recibido(p_numero_requerimiento varchar,
                                                                               p_usuario character varying,
                                                                               p_observacion varchar,
                                                                               OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion, fecha)
    VALUES (p_numero_requerimiento, 'RECIBIDO', p_usuario, p_observacion, CURRENT_TIMESTAMP);

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
