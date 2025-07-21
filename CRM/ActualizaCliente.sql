-- drop function puntos_venta.clientes_merge(jsonb);

CREATE OR REPLACE FUNCTION puntos_venta.clientes_merge(p_data jsonb)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _r                record;
    _interface_activo boolean;
    fecha_aprox       DATE;
BEGIN
    /*************************************************************************************************************/
    -- JSON:
    -- {
    --     "cedula_ruc": "",
    --     "tipo_documento": "",
    --     "nombres": "",
    --     "apellidos": "",
    --     "ciudad": "",
    --     "direccion": "",
    --     "telefono": "",
    --     "sexo": "",
    --     "estado_civil": "",
    --     "nivel_academico": "",
    --     "celular": "",
    --     "fecha_nacimiento": "",
    --     "edad_aproximada": 0,
    --     "email": "",
    --     "creacion_usuario": ""
    -- }
    /*************************************************************************************************************/

    -- Bandera de la interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Json
    SELECT t.cedula_ruc                             AS cedula_ruc,
           COALESCE(t.tipo_documento, '')           AS tipo_documento,
           COALESCE(UPPER(t.nombres), '')           AS nombres,
           COALESCE(UPPER(t.apellidos), '')         AS apellidos,
           COALESCE(UPPER(t.ciudad), '')            AS ciudad,
           COALESCE(UPPER(t.direccion), '')         AS direccion,
           COALESCE(t.telefono, '')                 AS telefono,
           COALESCE(t.sexo, '')                     AS sexo,
           COALESCE(t.estado_civil, '')             AS estado_civil,
           COALESCE(t.nivel_academico, '')          AS nivel_academico,
           COALESCE(t.celular, '')                  AS celular,
           NULLIF(t.fecha_nacimiento, '')           AS fecha_nacimiento,
           COALESCE(t.edad_aproximada, 0)           AS edad_aproximada,
           COALESCE(t.email, '')                    AS email,
           COALESCE(UPPER(t.creacion_usuario), '')  AS creacion_usuario,
           CURRENT_DATE                             AS creacion_fecha,
           TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS') AS creacion_hora
    INTO _r
    FROM JSONB_TO_RECORD(p_data)
             AS t (cedula_ruc TEXT, tipo_documento TEXT, nombres TEXT,
                   apellidos TEXT, ciudad TEXT, direccion TEXT,
                   telefono TEXT, sexo TEXT, estado_civil TEXT,
                   nivel_academico TEXT, celular TEXT, fecha_nacimiento TEXT,
                   edad_aproximada integer, email TEXT, creacion_usuario TEXT);

    -- Generar la fecha de nacimiento aproximada
    IF NULLIF(_r.fecha_nacimiento, '') IS NULL AND _r.edad_aproximada > 0 THEN
        fecha_aprox := _r.creacion_fecha - (_r.edad_aproximada * 366);
    END IF;

    INSERT INTO puntos_venta.clientes (cedula_ruc, direccion, telefono, apellidos, nombres,
                                       fecha_nacimiento, email, ciudad, tipo_cedula_ruc, sexo, estado_civil,
                                       nivel_academico, celular, fecha_nacimiento_aproximada)
    VALUES (_r.cedula_ruc, _r.direccion, _r.telefono, _r.apellidos, _r.nombres,
            NULLIF(_r.fecha_nacimiento::varchar, '')::DATE, _r.email, _r.ciudad, _r.tipo_documento,
            NULLIF(_r.sexo, ''), NULLIF(_r.estado_civil, ''), NULLIF(_r.nivel_academico, ''), _r.celular, fecha_aprox)
    ON CONFLICT (cedula_ruc) DO UPDATE
        SET direccion                   = EXCLUDED.direccion,
            telefono                    = EXCLUDED.telefono,
            apellidos                   = EXCLUDED.apellidos,
            nombres                     = EXCLUDED.nombres,
            fecha_nacimiento            = EXCLUDED.fecha_nacimiento,
            email                       = EXCLUDED.email,
            ciudad                      = EXCLUDED.ciudad,
            tipo_cedula_ruc             = EXCLUDED.tipo_cedula_ruc,
            sexo                        = EXCLUDED.sexo,
            estado_civil                = EXCLUDED.estado_civil,
            nivel_academico             = EXCLUDED.nivel_academico,
            celular                     = EXCLUDED.celular,
            fecha_nacimiento_aproximada = excluded.fecha_nacimiento_aproximada,
            fecha_ultima_actualizacion  = CURRENT_DATE;
END ;
$function$
;