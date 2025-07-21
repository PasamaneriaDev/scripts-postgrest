-- DROP FUNCTION puntos_venta.incidencias_cambiar_estado_noautorizado(in int4, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_cambiar_estado_noejecutado(p_numero_incidencia integer,
                                                                               p_observacion character varying,
                                                                               p_usuario character varying,
                                                                               OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    p_numero_email       numeric;
    p_correo_almacen     VARCHAR;
    p_correo_seguimiento VARCHAR;
    p_correos            VARCHAR;
    p_centro_costo       VARCHAR;
BEGIN
    -- ACTUALIZA el estado a no autorizado
    INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha, observacion)
    VALUES (p_numero_incidencia, 'NO EJECUTADO', p_usuario, CURRENT_TIMESTAMP, p_observacion);

    -- Busca el Centro de Costo de la incidencia
    SELECT subcentro, correo
    INTO p_centro_costo, p_correo_almacen
    FROM puntos_venta.incidencias pi
             JOIN activos_fijos.centros_costos cc ON pi.centro_costo = cc.codigo
    WHERE numero_incidencia = p_numero_incidencia;

    -- Busca los correos del personal de seguimiento
    SELECT alfa
    INTO p_correo_seguimiento
    FROM sistema.parametros
    WHERE modulo_id = 'SISTEMA'
      AND codigo = 'CORREO_AUTO_INCIDEN_REQUERIM';

    -- ENVIAR CORREO
    IF p_correo_almacen IS NULL THEN
        RAISE EXCEPTION 'No se ha configurado el EMAIL del Almacen';
    ELSEIF p_correo_seguimiento IS NULL THEN
        RAISE EXCEPTION 'No se ha configurado el EMAIL del Seguimiento';
    END IF;

    p_correos = p_correo_almacen || ',' || p_correo_seguimiento;

    -- Se obtiene el número de email
    SELECT MAX(t1.numero_email) + 1
    INTO p_numero_email
    FROM sistema.email_masivo_cabecera t1;

    -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
    INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email, imagen_email_cabecera,
                                              nombre_empresa, estado)
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Incidencia No Ejecutada.',
            'Saludos cordiales, <br/> El Incidencia Nro: ' || p_numero_incidencia::varchar ||
            ', no fue EJECUTADO. El motivo es: .<br/> ' ||
            COALESCE(p_observacion, '') || '<br/>' ||
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
