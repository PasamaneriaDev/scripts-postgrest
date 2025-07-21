-- DROP FUNCTION puntos_venta.vale_encerar(varchar);

CREATE OR REPLACE FUNCTION puntos_venta.vale_encerar(p_numero_vale character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    UPDATE puntos_venta.vales
    SET saldo = 0,
	    fecha_anulacion = current_timestamp
    WHERE numero_vale = p_numero_vale;
END ;
$function$
;
