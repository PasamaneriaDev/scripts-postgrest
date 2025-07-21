-- DROP FUNCTION puntos_venta.incidencias_grabar(in jsonb, out text);

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_grabar(p_data jsonb, OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo   boolean;
    _r                  record;
    p_numero_email      numeric;
    p_correos           VARCHAR;
    p_centro_costo      VARCHAR;
    p_numero_incidencia integer;
BEGIN
    /**************************************************************************************/
    -- Json
    -- {
    --   "centro_costo": "",
    --   "grupo": "",
    --   "observacion": "",
    --   "creacion_usuario": "",
    --   "ejecucion_usuario": "",
    -- }
    /**************************************************************************************/

    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Extraer del json
    SELECT COALESCE(UPPER(t.centro_costo), '')      AS centro_costo,
           COALESCE(UPPER(t.grupo), '')             AS grupo,
           COALESCE(UPPER(t.observacion), '')       AS observacion,
           COALESCE(UPPER(t.creacion_usuario), '')  AS creacion_usuario,
           COALESCE(UPPER(t.ejecucion_usuario), '') AS ejecucion_usuario
    INTO _r
    FROM JSONB_TO_RECORD(p_data) AS t (centro_costo VARCHAR(3),
                                       grupo varchar,
                                       observacion varchar,
                                       creacion_usuario VARCHAR(4),
                                       ejecucion_usuario VARCHAR(4)
        );


    -- INSERT
    INSERT INTO puntos_venta.incidencias (centro_costo, grupo, observacion)
    VALUES (_r.centro_costo, _r.grupo, _r.observacion)
    RETURNING numero_incidencia INTO p_numero_incidencia;

    INSERT INTO puntos_venta.incidencias_estados (numero_incidencia, estado, usuario, fecha)
    VALUES (p_numero_incidencia, 'EN TRAMITE', _r.creacion_usuario, CURRENT_TIMESTAMP);

    -- Cuando se Ingresa desde el CRM los usuarios de Cuenca ya registran al encargado
    IF COALESCE(_r.ejecucion_usuario, '') <> '' THEN
        PERFORM puntos_venta.incidencias_cambiar_estado_autorizado(p_numero_incidencia,
                                                                   _r.creacion_usuario,
                                                                   _r.ejecucion_usuario);
    ELSE
        -- ENVIAR CORREO
        -- Se obtiene los correos de los usuarios destinatarios
        SELECT alfa
        INTO p_correos
        FROM sistema.parametros
        WHERE modulo_id = 'SISTEMA'
          AND codigo = 'CORREO_AUTO_INCIDEN_REQUERIM';

        IF COALESCE(p_correos, '') = '' THEN
            RAISE EXCEPTION 'No se ha configurado el EMAIL para enviar la notificación de Incidencia o Requerimiento';
        END IF;

        -- Se busca el nombre del centro de costo
        SELECT subcentro
        INTO p_centro_costo
        FROM activos_fijos.centros_costos
        WHERE codigo = _r.centro_costo;

        -- Se obtiene el número de email
        SELECT MAX(t1.numero_email) + 1
        INTO p_numero_email
        FROM sistema.email_masivo_cabecera t1;

        -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
        INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email,
                                                  imagen_email_cabecera,
                                                  nombre_empresa, estado)
        VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Incidencia registrado.',
                'Saludos cordiales, <br/>' ||
                'Se ha registrado una nueva Incidencia en el sistema proveniente del almacen, ' || p_centro_costo ||
                '.<br/>' ||
                'Incidencia Nro: ' || p_numero_incidencia::varchar ||
                ', los detalles de la Incidencia se encuentran disponibles en el sistema.<br/> ' ||
                'Email Generado automáticamente por el sistema, no responda este mensaje ',
                '', 'Pasamanería S.A.', 'P');

        -- Se inserta en el detalle del email(Destinatarios del email)
        INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
        VALUES (p_numero_email, p_correos, 'Pasamanería S.A.');
    END IF;
    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
