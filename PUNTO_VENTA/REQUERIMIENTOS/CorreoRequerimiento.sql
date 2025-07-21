-- DROP FUNCTION puntos_venta.requerimientos_correo_bodega_md(VARCHAR);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_correo_bodega_md(p_numero_requerimiento varchar,
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
BEGIN

    -- Busca el Centro de Costo de la incidencia
    SELECT cc.subcentro
    INTO p_centro_costo, p_observacion, p_usuario_encargado
    FROM trabajo_proceso.requerimiento_guia pi
             JOIN activos_fijos.centros_costos cc ON pi.centro_costo_origen = cc.codigo
    WHERE pi.nro_requerimiento = p_numero_requerimiento;

    -- Busca los correos del personal encargado
    SELECT STRING_AGG(u.email, ',') AS correos
    INTO p_correos
    FROM roles.personal p
             JOIN sistema.usuarios u ON u.codigo = SUBSTR(p.codigo, 2, 4)
    WHERE p.centro_costo = 'S15'
      AND p.fecha_salida IS NULL;

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
    VALUES (p_numero_email, CURRENT_DATE, 'Recordatorio: Requerimiento Autorizado Pendiente de Atención',
            'Saludos cordiales, <br/>' ||
            'Este es un recordatorio sobre el Requerimiento Nro: ' || p_numero_requerimiento::varchar ||
            ', proveniente del almacén (' || p_centro_costo || ').<br/>' ||
            'Se solicita su atención lo más pronto posible.<br/>' ||
            'Puede revisar más detalles en el sistema.<br/>' ||
            'Este correo ha sido generado automáticamente, por favor no responda.',
            '', 'Pasamanería S.A.', 'P');

    -- Se inserta en el detalle del email(Destinatarios del email)
    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (p_numero_email, p_correos, 'Pasamanería S.A.');

    -- Se actualiza el estado del requerimiento
    INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion, fecha)
    VALUES (p_numero_requerimiento, 'AUTORIZADO', p_usuario, 'CORREO ENVIADO', CURRENT_TIMESTAMP);
    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
