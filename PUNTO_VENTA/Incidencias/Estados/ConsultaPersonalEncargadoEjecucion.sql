-- drop function puntos_venta.incidencias_consultar_usuarios_ejecucion();

CREATE OR REPLACE FUNCTION puntos_venta.incidencias_consultar_usuarios_ejecucion()
    RETURNS TABLE
            (
                usuario varchar,
                nombres  text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT u.codigo, u.nombres::text as nombres
        FROM sistema.usuarios u
        WHERE u.recibe_incidencias;
END
$function$
;



