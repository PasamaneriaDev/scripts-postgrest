-- DROP FUNCTION puntos_venta.requerimientos_almacenes_grabar(in jsonb, out text);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_almacenes_grabar(p_data jsonb, OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo      boolean;
    _r                     record;
    _d                     record;
    p_numero_email         numeric;
    p_correos              VARCHAR;
    p_centro_costo         VARCHAR;
    p_numero_requerimiento numeric;
    v_autorizar_auto       boolean = FALSE;
BEGIN
    /**************************************************************************************/
    -- Json
    -- {
    --   "centro_costo": "",
    --   "creacion_usuario": "",
    --   "fecha_requerimiento": "",
    --   "detalles": [
    --       {
    --           "item": "",
    --           "cantidad": ""
    --       },
    --       {...}
    --   ]
    -- }
    /**************************************************************************************/
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    SELECT COALESCE(UPPER(t.centro_costo), '')     AS centro_costo,
           COALESCE(UPPER(t.creacion_usuario), '') AS creacion_usuario,
           COALESCE(t.fecha_requerimiento, '')     AS fecha_requerimiento,
           (p_data ->> 'detalles')::jsonb          AS detalles
    INTO _r
    FROM JSONB_TO_RECORD(p_data) AS t (centro_costo VARCHAR(3),
                                       creacion_usuario VARCHAR(4),
                                       fecha_requerimiento VARCHAR(10)
        );

    -- Validar si el usuario puede autorizar automáticamente
    WITH correos AS (SELECT STRING_TO_ARRAY(alfa, ',') AS email_list
                     FROM sistema.parametros
                     WHERE modulo_id = 'SISTEMA'
                       AND codigo = 'CORREO_AUTO_INCIDEN_REQUERIM'),
         usuario_email AS (SELECT email
                           FROM sistema.usuarios
                           WHERE codigo = '9665')
    SELECT CASE
               WHEN ue.email = ANY (c.email_list) THEN TRUE
               ELSE FALSE
               END AS email_status
    INTO v_autorizar_auto
    FROM correos c,
         usuario_email ue;

    -- Actualiza el numero de requerimiento
    FOR _d IN SELECT j.item,
                     j.cantidad,
                     j.comentario
              FROM JSON_TO_RECORDSET(_r.detalles::json) AS j(item VARCHAR(15), cantidad numeric, comentario VARCHAR(100))
        LOOP
            UPDATE sistema.parametros
            SET numero = numero + 1
            WHERE codigo = 'NUM_REQUERIMIEN'
            RETURNING numero
                INTO p_numero_requerimiento;

            -- La fecha de requerimiento se guarda en nulo para poder autorizarlo
            WITH t AS (
                INSERT INTO trabajo_proceso.requerimiento_guia AS rg (nro_requerimiento,
                                                                      tipo_requerimiento,
                                                                      centro_costo_origen,
                                                                      centro_costo_destino,
                                                                      codigo_orden,
                                                                      item,
                                                                      cantidad_solicitada,
                                                                      fecha_solicitud,
                                                                      operador_solicita,
                                                                      no_entregado,
                                                                      comentario,
                                                                      fecha_requerimiento,
                                                                      urgente)
                    VALUES (LPAD(TRIM(p_numero_requerimiento::int::varchar), 10, '0'),
                            'EGR',
                            _r.centro_costo,
                            'S15',
                            NULL,
                            _d.item,
                            _d.cantidad,
                            _r.fecha_requerimiento::date, --CURRENT_DATE,
                            _r.creacion_usuario,
                            'f',
                            _d.comentario,
                            NULL,
                            TRUE)
                    RETURNING rg.nro_requerimiento, rg.tipo_requerimiento, rg.centro_costo_origen,
                        rg.centro_costo_destino, rg.codigo_orden, rg.item, rg.cantidad_solicitada,
                        rg.fecha_solicitud, rg.operador_solicita, rg.no_entregado, rg.comentario,
                        rg.fecha_requerimiento, rg.urgente)
            -- Interfaz
            INSERT
            INTO sistema.interface
                (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
            SELECT 'CUENTAS POR COBRAR',
                   'INSERT',
                   'requguia',
                   _r.creacion_usuario,
                   'F:\home\spp\TRABPROC\DATA\',
                   '',
                   'REPLACE ' ||
                   '  numrequeri WITH [' || t.nro_requerimiento || '], ' ||
                   '  tiporequer WITH [' || t.tipo_requerimiento || '], ' ||
                   '  centcosori WITH [' || t.centro_costo_origen || '], ' ||
                   '  centcosdes WITH [' || t.centro_costo_destino || '], ' ||
                   '  item WITH [' || t.item || '], ' ||
                   '  cantsolici WITH [' || t.cantidad_solicitada::varchar || '], ' ||
                   '  fehosolici WITH {^ ' || t.fecha_solicitud || '}, ' ||
                   '  opersolici WITH [' || t.operador_solicita || '], ' ||
                   '  comentario WITH [' || t.comentario || '], ' ||
                   '  noentregad WITH .f., ' ||
                   '  fechareque WITH {^' || COALESCE(t.fecha_requerimiento::text, '') || '}, ' ||
                   '  urgente WITH ' || CASE WHEN t.urgente THEN '.t.' ELSE '.f.' END
            FROM t
            WHERE _interface_activo;

            -- Autorizar automáticamente
            IF v_autorizar_auto THEN
                SELECT puntos_venta.requerimientos_cambiar_estado_autorizado(
                               LPAD(TRIM(p_numero_requerimiento::int::varchar), 10, '0'), _r.creacion_usuario, '', TRUE)
                INTO respuesta;
            END IF;
        END LOOP;

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
    INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email, imagen_email_cabecera,
                                              nombre_empresa, estado)
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Requerimiento registrado.',
            'Saludos cordiales, <br/>' ||
            'Se ha registrado un nuevo Requerimiento en el sistema proveniente del almacen, ' || p_centro_costo ||
            '.<br/>' ||
            'Puede hacer el seguimiento del Requerimiento dentro del sistema.<br/> ' ||
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
