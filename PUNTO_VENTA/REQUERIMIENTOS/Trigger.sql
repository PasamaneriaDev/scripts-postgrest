-- DROP FUNCTION trabajo_proceso.actualizar_estado_requerimiento();

CREATE OR REPLACE FUNCTION trabajo_proceso.actualizar_estado_requerimiento()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$function$
DECLARE
    p_correos      VARCHAR;
    p_centro_costo VARCHAR;
    p_numero_email numeric;
BEGIN
    -- 2025-02-14: Trigger para los Requerimientos de Almacenes
    IF NEW.centro_costo_origen IN (SELECT DISTINCT pa.centro_costo
                                   FROM SISTEMA.parametros_almacenes AS pa) THEN
        IF TG_OP = 'INSERT' THEN
            INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion)
            VALUES (NEW.nro_requerimiento, 'EN TRAMITE', 'CAJA', '');
        ELSIF TG_OP = 'UPDATE' THEN
            IF OLD.fecha_entregada IS NULL AND NEW.fecha_entregada IS NOT NULL THEN
                INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion)
                VALUES (NEW.nro_requerimiento, 'ENVIADO', '', '');

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
                WHERE codigo = new.centro_costo_origen;

                -- Se obtiene el número de email
                SELECT MAX(t1.numero_email) + 1
                INTO p_numero_email
                FROM sistema.email_masivo_cabecera t1;

                -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
                INSERT INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email,
                                                          imagen_email_cabecera,
                                                          nombre_empresa, estado)
                VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Requerimiento Enviado.',
                        'Saludos cordiales, <br/>' ||
                        'Se registro el ENVIO al almacen: ' || p_centro_costo || ', del Requerimiento: ' ||
                        new.nro_requerimiento || '<br/>' ||
                            -- ', correspondiente a: <br/>' ||
                            -- 'Item: ' || new.item || ', Cantidad Solicitada: ' || new.cantidad_solicitada || ', ' ||
                            -- 'Cantidad Enviada: ' || new.cantidad_entragada || '<br/> <br/>' ||
                        'Puede hacer el seguimiento del Requerimiento dentro del sistema.<br/> ' ||
                        'Email Generado automáticamente por el sistema, no responda este mensaje ',
                        '', 'Pasamanería S.A.', 'P');

                -- Se inserta en el detalle del email(Destinatarios del email)
                INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
                VALUES (p_numero_email, p_correos, 'Pasamanería S.A.');
            ELSIF old.activo = TRUE AND new.activo = FALSE THEN
                INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion)
                VALUES (NEW.nro_requerimiento, 'NO ENVIADO', 'CAJA', '');
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END ;
$function$
;
