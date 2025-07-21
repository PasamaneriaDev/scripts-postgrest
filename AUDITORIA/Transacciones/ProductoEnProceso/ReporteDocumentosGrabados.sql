-- drop function auditoria.reporte_tomas_produccion_grabadas(p_bodega varchar, p_ubicacion varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_tomas_produccion_grabadas(p_bodega varchar, p_ubicacion varchar)
    RETURNS TABLE
            (
                documento CHARACTER VARYING,
                item      CHARACTER VARYING,
                cantidad  NUMERIC,
                conos     numeric,
                tara      NUMERIC,
                cajon     NUMERIC,
                constante NUMERIC,
                bodega    CHARACTER VARYING,
                ubicacion CHARACTER VARYING,
                muestra   text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        (SELECT a.documento,
                a.item,
                a.cantidad,
                a.conos,
                a.tara,
                a.cajon,
                a.constante,
                a.bodega,
                a.ubicacion,
                '' AS muestra
         FROM control_inventarios.ajustes a
         WHERE a.status <> 'V'
           AND a.tipo = 'T'
           AND a.bodega = p_bodega
           AND (p_ubicacion = '' OR a.ubicacion = p_ubicacion)
           AND a.muestra IS NULL
         UNION ALL
         SELECT a.documento,
                a.item,
                mu.cantidad,
                mu.conos,
                mu.tara,
                0,
                a.constante,
                a.bodega,
                a.ubicacion,
                'X' AS muestra
         FROM control_inventarios.ajustes a
                  JOIN LATERAL (SELECT (STRING_TO_ARRAY(line, CHR(9)))[1]::numeric AS linea,
                                       (STRING_TO_ARRAY(line, CHR(9)))[2]::numeric AS cantidad,
                                       (STRING_TO_ARRAY(line, CHR(9)))[3]::numeric AS conos,
                                       (STRING_TO_ARRAY(line, CHR(9)))[4]::numeric AS tara
                                FROM UNNEST(STRING_TO_ARRAY(a.muestra, CHR(10))) AS line
                                where (STRING_TO_ARRAY(line, CHR(9)))[1]::numeric is not null
                                ORDER BY (STRING_TO_ARRAY(line, CHR(9)))[1]::numeric) AS mu ON TRUE
         WHERE a.status <> 'V'
           AND a.tipo = 'T'
           AND a.bodega = p_bodega
           AND (p_ubicacion = '' OR a.ubicacion = p_ubicacion)
           AND a.muestra IS NOT NULL)
            ORDER BY documento, item, muestra;
END
$function$
;