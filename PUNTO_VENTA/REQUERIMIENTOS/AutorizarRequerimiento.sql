-- DROP FUNCTION puntos_venta.requerimientos_cambiar_estado_autorizado(integer, varchar, varchar, boolean);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_cambiar_estado_autorizado(p_numero_requerimiento varchar,
                                                                                 p_usuario character varying,
                                                                                 p_observacion varchar,
                                                                                 se_autoriza boolean,
                                                                                 OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo boolean;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    IF se_autoriza THEN
        -- Acutaliza la fecha para que aparezca en bodega
        WITH t AS (
            UPDATE trabajo_proceso.requerimiento_guia fd
                SET fecha_requerimiento = fecha_solicitud
                WHERE nro_requerimiento = p_numero_requerimiento
                RETURNING fd.fecha_requerimiento)
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'AUDITORIA'
             , 'UPDATE1'
             , 'requguia'
             , p_usuario
             , 'F:\home\spp\TRABPROC\DATA\'
             , ''
             , 'UPDATE F:\home\spp\TRABPROC\DATA\requguia ' ||
               'SET fechareque = {^' || TO_CHAR(t.fecha_requerimiento, 'YYYY-MM-DD') || '} '
                   'Where numrequeri = [' || p_numero_requerimiento || '] '
        FROM t
        WHERE _interface_activo;

        INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, fecha)
        VALUES (p_numero_requerimiento, 'AUTORIZADO', p_usuario, CURRENT_TIMESTAMP);

    ELSE
        INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion, fecha)
        VALUES (p_numero_requerimiento, 'NO AUTORIZADO', p_usuario, p_observacion, CURRENT_TIMESTAMP);
    END IF;

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
