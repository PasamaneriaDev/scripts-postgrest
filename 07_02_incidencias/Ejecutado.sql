-- DROP FUNCTION puntos_venta.incidencias_grabar(in jsonb, out text);

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_cambiar_estado_ejecutado(p_numero_incidencia integer,
                                                                             p_usuario varchar,
                                                                             p_observacion varchar,
                                                                             OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    p_numero_email             numeric;
    p_correos                  VARCHAR;
    p_centro_costo             VARCHAR;
    p_nombre_usuario_encargado VARCHAR;
BEGIN
    INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha, observacion)
    VALUES (p_numero_incidencia, 'EJECUTADO', p_usuario, CURRENT_TIMESTAMP, p_observacion);

    -- Busca el Centro de Costo de la incidencia
    SELECT cc.subcentro, uej.nombres
    INTO p_centro_costo, p_nombre_usuario_encargado
    FROM puntos_venta.incidencias pi
             JOIN activos_fijos.centros_costos cc ON pi.centro_costo = cc.codigo
             LEFT JOIN sistema.usuarios uej ON pi.ejecucion_usuario = uej.codigo
    WHERE pi.numero_incidencia = p_numero_incidencia;

    -- ENVIAR CORREO
    -- Se obtiene los correos de los usuarios destinatarios
    SELECT alfa
    INTO p_correos
    FROM sistema.parametros
    WHERE modulo_id = 'SISTEMA'
      AND codigo = 'CORREO_AUTO_INCIDEN_REQUERIM';

    IF COALESCE(p_correos, '') = '' THEN
        RAISE EXCEPTION 'No se ha configurado el EMAIL para enviar la notificación de la Incidencia';
    END IF;

    -- Se obtiene el número de email
    SELECT MAX(t1.numero_email) + 1
    INTO p_numero_email
    FROM sistema.email_masivo_cabecera t1;

    -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
    INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email,
                                              imagen_email_cabecera,
                                              nombre_empresa, estado)
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Incidencia Ejecutada.',
            'Saludos cordiales, <br/> La Incidencia Nro: ' || p_numero_incidencia::varchar ||
            ' , del Almacen: ' || p_centro_costo || ', fue Ejecutada por el Usuario: ' ||
            COALESCE(p_nombre_usuario_encargado, '') || '.<br/>' ||
            CASE
                WHEN COALESCE(p_observacion, '') <> ''
                    THEN 'Agrego la siguiente observacion: <br/>' || p_observacion || '<br/>'
                ELSE '' END ||
            ', los detalles de la Incidencia se encuentran disponibles en el sistema.<br/> ' ||
            'Email Generado automáticamente por el sistema, no responda este mensaje ',
            '', 'Pasamanería S.A.', 'P');

    -- Se inserta en el detalle del email(Destinatarios del email)
    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (p_numero_email, p_correos, 'Pasamanería S.A.');
    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
