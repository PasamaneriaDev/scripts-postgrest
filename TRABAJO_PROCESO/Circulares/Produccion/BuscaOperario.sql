-- drop function trabajo_proceso.operador_buscar_x_codigo_barra(varchar)

CREATE OR REPLACE FUNCTION trabajo_proceso.operador_buscar_x_codigo_barra(string_buscar character varying)
    RETURNS TABLE
            (
                codigo  varchar,
                nombres text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    IF (SELECT * FROM "public".isdigit(string_buscar)) THEN
        RETURN QUERY
            SELECT p.codigo                                                                  AS codigo,
                   CONCAT(p.apellido_paterno, ' ', p.apellido_materno, ' ', p.nombre1, ' ', p.nombre2) AS nombres
            FROM roles.personal p
            WHERE p.cedula_ruc =
                  TRIM(SUBSTRING(string_buscar FROM 2 FOR 9)) || '-' || TRIM(SUBSTRING(string_buscar FROM 11 FOR 1))
              AND p.fecha_salida IS NULL;
    ELSE
        RETURN QUERY
            SELECT p.codigo                                                              AS codigo,
                   CONCAT(p.apellido_paterno, ' ', p.apellido_materno, ' ', p.nombre1, ' ', p.nombre2) AS nombres
            FROM roles.personal p
            WHERE p.codigo = string_buscar
              AND p.fecha_salida IS NULL;
    END IF;
END
$function$
;
