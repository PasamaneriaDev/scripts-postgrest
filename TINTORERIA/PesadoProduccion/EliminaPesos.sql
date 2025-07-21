-- DROP FUNCTION trabajo_proceso.actualiza_estado_tintoreria(p_id varchar, p_estado varchar, p_observacion varchar, OUT respuesta text)

CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_pesos_balanza_elimina(p_codigo_orden varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    -- DELETE FROM trabajo_proceso.tintoreria_pesos_balanza
    -- WHERE codigo_orden = $1_
    --   AND activo
    UPDATE trabajo_proceso.tintoreria_pesos_balanza
    SET activo = FALSE
    WHERE codigo_orden = p_codigo_orden;
END ;
$function$
;
