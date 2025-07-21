-- DROP FUNCTION puntos_venta.requerimientos_almacenes_grabar(in jsonb, out text);

CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_cambiar_cantidad_solicitada(p_numero_requerimiento varchar,
                                                                                   p_usuario varchar,
                                                                                   p_cantidad numeric,
                                                                                   OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo       boolean;
    old_cantidad_solicitada varchar;
BEGIN
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Obtiene la cantidad solicitada anterior
    SELECT cantidad_solicitada
    INTO old_cantidad_solicitada
    FROM trabajo_proceso.requerimiento_guia
    WHERE nro_requerimiento = p_numero_requerimiento;

    -- Actualiza la cantidad solicitada
    WITH t AS (
        UPDATE trabajo_proceso.requerimiento_guia fd
            SET cantidad_solicitada = p_cantidad::varchar
            WHERE nro_requerimiento = p_numero_requerimiento
            RETURNING fd.cantidad_solicitada)
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
           'SET cantsolici = [' || t.cantidad_solicitada::varchar || '] '
               'Where numrequeri = [' || p_numero_requerimiento || '] '
    FROM t
    WHERE _interface_activo;

    INSERT INTO puntos_venta.requerimientos_estados (nro_requerimiento, estado, usuario, observacion, fecha)
    VALUES ( p_numero_requerimiento, 'EN TRAMITE', p_usuario,
             'CANTIDAD MODIFICADA: ' || old_cantidad_solicitada::varchar || ' -> ' || p_cantidad::varchar
           , CURRENT_TIMESTAMP);
    /****************/
    respuesta = 'OK';
    /****************/
END ;
$function$
;
