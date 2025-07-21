-- DROP FUNCTION puntos_venta.incidencias_cambiar_estado_noautorizado(in int4, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION control_inventarios.ubicacion_insertar(p_bodega varchar,
                                                                  p_ubicacion varchar,
                                                                  p_usuario varchar,
                                                                  OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
BEGIN
    INSERT INTO control_inventarios.id_ubicaciones(bodega, ubicacion, existencia, creacion_usuario, creacion_fecha,
                                                   creacion_hora, migracion)
    VALUES (p_bodega, p_ubicacion, true, p_usuario, current_date,  TO_CHAR(CURRENT_TIMESTAMP, 'HH24:MI:SS') , 'NO');

    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
