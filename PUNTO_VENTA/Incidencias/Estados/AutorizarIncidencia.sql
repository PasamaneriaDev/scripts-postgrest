    -- DROP FUNCTION puntos_venta.incidencias_cambiar_estado_autorizado(in int4, in varchar, in varchar, out text);

    CREATE OR REPLACE FUNCTION puntos_venta.incidencias_cambiar_estado_autorizado(p_numero_incidencia integer,
                                                                                  p_usuario character varying,
                                                                                  p_usuario_encargado character varying,
                                                                                  OUT respuesta text)
        RETURNS text
        LANGUAGE plpgsql
    AS
    $function$
    DECLARE
        p_observacion  VARCHAR;
        p_numero_email numeric;
        p_correos      VARCHAR;
        p_centro_costo VARCHAR;
    BEGIN
        -- ACTUALIZA el usuario encargado
        UPDATE puntos_venta.incidencias
        SET ejecucion_usuario = p_usuario_encargado
        WHERE numero_incidencia = p_numero_incidencia;

        PERFORM puntos_venta.incidencias_enviar_correo_encargado(p_numero_incidencia, p_usuario);

        /***************/
        respuesta = 'OK';
        /***************/
    END;
    $function$
    ;


