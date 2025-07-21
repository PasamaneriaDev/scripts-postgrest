/*
drop FUNCTION auditoria.papeletas_generar(fecha date,
                                                       bodega varchar,
                                                       ubicacion varchar,
                                                       cantidad numeric,
                                                       creacion_usuario varchar)
*/
CREATE OR REPLACE FUNCTION auditoria.papeletas_generar(fecha date,
                                                       bodega varchar,
                                                       ubicacion varchar,
                                                       cantidad numeric,
                                                       creacion_usuario varchar,
                                                       OUT numero_papeleta_max integer)
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
BEGIN
    INSERT INTO auditoria.papeletas_inventario (fecha, bodega, ubicacion, creacion_usuario)
    SELECT fecha, bodega, ubicacion, creacion_usuario
    FROM GENERATE_SERIES(1, cantidad);

    numero_papeleta_max = auditoria.papeletas_obtiene_maximo();
END;
$function$;