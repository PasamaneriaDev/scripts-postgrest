-- DROP FUNCTION puntos_venta.incidencias_enviar_correo_encargado(p_numero_incidencia integer)

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_enviar_correo_encargado(p_numero_incidencia integer,
                                                                            p_usuario character varying,
                                                                            OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    p_observacion       VARCHAR;
    p_numero_email      numeric;
    p_correos           VARCHAR;
    p_centro_costo      VARCHAR;
    p_usuario_encargado VARCHAR;
    p_reenvio           varchar;
BEGIN

    -- Inserta el estado de la incidencia
    p_reenvio := CASE
                     WHEN EXISTS (SELECT 1
                                  FROM puntos_venta.incidencias_estados
                                  WHERE numero_incidencia = p_numero_incidencia
                                    AND estado = 'AUTORIZADO')
                         THEN 'CORREO REENVIADO' END;

    INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha, observacion)
    VALUES (p_numero_incidencia, 'AUTORIZADO', p_usuario, CURRENT_TIMESTAMP, p_reenvio);

    -- Busca el Centro de Costo de la incidencia
    SELECT cc.subcentro, pi.observacion, pi.ejecucion_usuario
    INTO p_centro_costo, p_observacion, p_usuario_encargado
    FROM puntos_venta.incidencias pi
             JOIN activos_fijos.centros_costos cc ON pi.centro_costo = cc.codigo
    WHERE pi.numero_incidencia = p_numero_incidencia;

    -- Busca los correos del personal encargado
    SELECT email
    INTO p_correos
    FROM sistema.usuarios
    WHERE codigo = p_usuario_encargado;

    -- ENVIAR CORREO
    IF p_correos IS NULL THEN
        RAISE EXCEPTION 'No se ha configurado el EMAIL para enviar la notificación';
    END IF;

    -- Se obtiene el número de email
    SELECT MAX(t1.numero_email) + 1
    INTO p_numero_email
    FROM sistema.email_masivo_cabecera t1;

    -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
    INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email, imagen_email_cabecera,
                                              nombre_empresa, estado)
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Incidencia Autorizada.',
            'Saludos cordiales, <br/> El Incidencia Nro: ' || p_numero_incidencia::varchar || ', ' ||
            'proveniente del almacen, ' || p_centro_costo || ', se le ha asignado. El Motivo es: .<br/> ' ||
            COALESCE(p_observacion, '') || '<br/>' ||
            'Puede Revisar mas detalles en el sistema. <br/>' ||
            'Email Generado automáticamente por el sistema, no responda este mensaje ',
            '', 'Pasamanería S.A.', 'P');

    -- Se inserta en el detalle del email(Destinatarios del email)
    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (p_numero_email, p_correos, 'Pasamanería S.A.');

    -- Inserta en la tabla de historico
    INSERT INTO puntos_venta.correos_enviados_encargados_incidencias(numero_incidencia, fecha)
    VALUES (p_numero_incidencia, CURRENT_TIMESTAMP);

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
