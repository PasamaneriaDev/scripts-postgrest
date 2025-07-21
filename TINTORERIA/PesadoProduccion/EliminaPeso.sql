-- DROP FUNCTION trabajo_proceso.actualiza_estado_tintoreria(p_id varchar, p_estado varchar, p_observacion varchar, OUT respuesta text)

CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_peso_balanza_elimina(p_id integer)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    -- DELETE
    -- FROM trabajo_proceso.tintoreria_pesos_balanza
    -- WHERE tintoreria_pesos_balanza_id = p_id;
    UPDATE trabajo_proceso.tintoreria_pesos_balanza
    SET activo    = FALSE,
        ubicacion = '',
        bodega    = ''
    WHERE tintoreria_pesos_balanza_id = p_id;
END ;
$function$
;
