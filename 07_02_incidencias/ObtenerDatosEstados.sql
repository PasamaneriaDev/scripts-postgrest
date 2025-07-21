-- drop function puntos_venta.incidencias_estados_obtener_fecha(integer, text);
CREATE OR REPLACE FUNCTION puntos_venta.incidencias_estados_obtener_fecha(p_numero_incidencia integer,
                                                                          p_estado varchar,
                                                                          OUT respuesta timestamp)
    RETURNS timestamp
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    SELECT a.fecha
    INTO respuesta
    FROM puntos_venta.incidencias_estados a
    WHERE a.numero_incidencia = p_numero_incidencia
      AND a.estado = p_estado;
END;
$function$
;


CREATE OR REPLACE FUNCTION puntos_venta.incidencias_estados_obtener_observacion(p_numero_incidencia integer,
                                                                                p_estado varchar,
                                                                                OUT respuesta varchar)
    RETURNS varchar
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    SELECT a.observacion
    INTO respuesta
    FROM puntos_venta.incidencias_estados a
    WHERE a.numero_incidencia = p_numero_incidencia
      AND a.estado = p_estado;
END;
$function$
;

SELECT *
FROM puntos_venta.incidencias_estados;



select puntos_venta.incidencias_estados_obtener_fecha(1, 'EN sTRAMITE');