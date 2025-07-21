-- DROP FUNCTION puntos_venta.grabar_reclamo(in jsonb, out text);

CREATE OR REPLACE FUNCTION puntos_venta.grabar_reclamo(p_data jsonb, OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _r                    record;
    _d                    record;
    p_numero_reclamo      numeric;
    p_correos             VARCHAR;
    p_correo_destinatario VARCHAR;
    p_correo_calidad      VARCHAR;
    p_numero_email        numeric;
    p_centro_costo        VARCHAR;
    p_fecha_recepcion     timestamp;
BEGIN
    /********************************************************************************************************/
    -- JSON
    --     {
    --         "centro_costo": "",
    --         "nombre_cliente": "",
    --         "fecha_reclamo": "",
    --         "fecha_compra": "",
    --         "problema_solucionado": "",
    --         "solucion": ""
    --         "productos_lavado": "",
    --         "metodo_lavado": "",
    --         "metodo_secado": "",
    --         "observaciones": "",
    --         "numero_transferencia": "",
    --         "creacion_usuario": ""
    --         "recepcion_usuario": "",
    --         "recepcion_fecha": "",
    --         "detalles": [
    --             {
    --                 "item": "",
    --                 "cantidad": "",
    --                 "periodo": "",
    --                 "observacion_item": "",
    --                 "codigo_defecto": ""
    --             },
    --             {...}
    --         ]
    --     }
    /********************************************************************************************************/

    SELECT COALESCE(UPPER(t.centro_costo), '')                             AS centro_costo,
           COALESCE(UPPER(t.nombre_cliente), '')                           AS nombre_cliente,
           COALESCE(t.fecha_reclamo, CURRENT_DATE)                         AS fecha_reclamo,
           CASE WHEN t.fecha_compra = '' THEN NULL ELSE t.fecha_compra END AS fecha_compra,
           --COALESCE(t.fecha_compra, CURRENT_DATE)                   AS fecha_compra,
           COALESCE(t.problema_solucionado, FALSE)                         AS problema_solucionado,
           COALESCE(UPPER(t.solucion), '')                                 AS solucion,
           COALESCE(UPPER(t.productos_lavado), '')                         AS productos_lavado,
           COALESCE(UPPER(t.metodo_lavado), '')                            AS metodo_lavado,
           COALESCE(UPPER(t.metodo_secado), '')                            AS metodo_secado,
           COALESCE(UPPER(t.observaciones), '')                            AS observaciones,
           COALESCE(UPPER(t.numero_transferencia), '')                     AS numero_transferencia,
           COALESCE(UPPER(t.creacion_usuario), '')                         AS creacion_usuario,
           COALESCE(UPPER(t.recepcion_usuario), '')                        AS recepcion_usuario,
           TO_TIMESTAMP(t.recepcion_fecha, 'YYYY-MM-DD HH24:MI:SS')        AS recepcion_fecha,
           (p_data ->> 'detalles')::jsonb                                  AS detalles
    INTO _r
    FROM JSONB_TO_RECORD(p_data) AS t (centro_costo VARCHAR(3),
                                       nombre_cliente VARCHAR(70),
                                       fecha_reclamo DATE,
                                       fecha_compra VARCHAR,
                                       problema_solucionado BOOLEAN,
                                       solucion VARCHAR(100),
                                       productos_lavado VARCHAR(30),
                                       metodo_lavado VARCHAR(30),
                                       metodo_secado VARCHAR(30),
                                       observaciones VARCHAR(300),
                                       numero_transferencia VARCHAR(10),
                                       creacion_usuario VARCHAR(4),
                                       recepcion_usuario VARCHAR(4),
                                       recepcion_fecha varchar);
    /********************************************************************************************************/
    -- Cuando se Graba el Reclamo desde Atencion al Cliente, el usuario recepcion y creacion sera el mismo
    -- Por lo que tambien se toma la fecha de recepcion automaticamente...

    IF _r.recepcion_fecha IS NULL THEN
        IF _r.creacion_usuario = _r.recepcion_usuario AND _r.centro_costo = 'V05' THEN
            p_fecha_recepcion = CURRENT_TIMESTAMP;
        ELSE
            p_fecha_recepcion = NULL;
        END IF;
    ELSE
        p_fecha_recepcion = _r.recepcion_fecha;
    END IF;

    -- Inserta en la tabla cabecera_reclamo
    INSERT INTO puntos_venta.reclamos_cabecera (centro_costo,
                                                nombre_cliente,
                                                fecha_reclamo,
                                                fecha_compra,
                                                problema_solucionado,
                                                solucion,
                                                productos_lavado,
                                                metodo_lavado,
                                                metodo_secado,
                                                observaciones,
                                                numero_transferencia,
                                                creacion_usuario,
                                                creacion_fecha,
                                                recepcion_usuario,
                                                recepcion_fecha)
    VALUES (_r.centro_costo,
            _r.nombre_cliente,
            _r.fecha_reclamo,
            _r.fecha_compra::DATE,
            _r.problema_solucionado,
            _r.solucion,
            _r.productos_lavado,
            _r.metodo_lavado,
            _r.metodo_secado,
            _r.observaciones,
            _r.numero_transferencia,
            _r.creacion_usuario,
            CURRENT_TIMESTAMP,
            _r.recepcion_usuario,
            p_fecha_recepcion)
    RETURNING numero_reclamo INTO p_numero_reclamo;

    /********************************************************************************************************/
    -- Inserta en el detalle del reclamo
    FOR _d IN SELECT j.item,
                     j.cantidad,
                     COALESCE(j.periodo, 0)           AS periodo,
                     COALESCE(j.observacion_item, '') AS observacion_item,
                     j.codigo_defecto
              FROM JSON_TO_RECORDSET(_r.detalles::json) AS j(item VARCHAR(15), cantidad numeric, periodo numeric,
                                                             observacion_item VARCHAR, codigo_defecto varchar)
        LOOP
            IF _d.periodo = 0 AND COALESCE(_r.nombre_cliente, '') = '' THEN
                RAISE EXCEPTION 'El periodo no puede estar vacio si es Reclamo de Almacen';
            END IF;
            INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre,
                                                       codigo_defecto, observaciones)
            VALUES (p_numero_reclamo, _d.item, _d.cantidad, _d.periodo, _d.codigo_defecto, _d.observacion_item);
        END LOOP;
    -- Respuesta
    respuesta = p_numero_reclamo::text;

    /********************************************************************************************************/
    -- ENVIO DEL MAIL
    -- Busca los correos de los usuarios que deben recibir el email
    -- 1. Busca el correo del Usuario Destinatario
    SELECT email
    INTO p_correo_destinatario
    FROM sistema.usuarios
    WHERE codigo = _r.recepcion_usuario;

    IF COALESCE(p_correo_destinatario, '') = '' THEN
        RAISE EXCEPTION 'El Correo del Usuario %, no se encuentra configurado, CONTACTE CON SISTEMAS', _r.recepcion_usuario;
    END IF;

    -- 2 Se busca el correo del Encargado de Calidad
    SELECT ALFA
    INTO p_correo_calidad
    FROM sistema.parametros
    WHERE modulo_id = 'CRM'
      AND codigo = 'CORREO_AUTO_ENCARGADO_CALIDAD';

    IF COALESCE(p_correo_calidad, '') = '' THEN
        RAISE EXCEPTION 'El Correo del Encargado de Calidad no se encuentra configurado, CONTACTE CON SISTEMAS';
    END IF;

    IF _r.creacion_usuario = _r.recepcion_usuario THEN
        p_correos = p_correo_calidad;
    ELSE
        p_correos = p_correo_destinatario || ',' || p_correo_calidad;
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
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de Reclamo/Devolución registrado.',
            'Estimado equipo de Atención al Cliente, <br/>' ||
            'Se ha registrado un nuevo reclamo/devolución en el sistema proveniente del almacen, ' || p_centro_costo ||
            '.<br/>' ||
            'Reclamo Nro: ' || p_numero_reclamo::varchar ||
            ', los detalles del reclamo se encuentran disponibles en el sistema.<br/> ' ||
            'Email Generado automáticamente por el sistema, no responda este mensaje ',
            '', 'Pasamanería S.A.', 'P');

    -- Se inserta en el detalle del email(Destinatarios del email)
    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (p_numero_email, p_correos, 'Atencion al Cliente');

END;
$function$
;
