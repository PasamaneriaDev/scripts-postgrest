-- drop function control_inventarios.unidades_formato_reporte(p_unidad varchar, p_unid_desp int);

CREATE OR REPLACE FUNCTION control_inventarios.unidades_formato_reporte(p_unidad varchar, p_unid_desp numeric)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN CASE
               WHEN p_unidad = 'UN' THEN 'UNIDAD'
               WHEN p_unidad = 'PQ' THEN 'PAQUETE'
               WHEN p_unidad = 'KG' THEN 'KILOGRAMO'
               WHEN p_unidad = 'PZ' THEN CAST(p_unid_desp::int AS varchar) || p_unidad
               WHEN p_unidad = 'MD50' THEN 'MADEJA'
               WHEN p_unidad = 'PR' THEN 'GRUESA'
               WHEN p_unidad IN ('MT', 'YD') THEN CAST(p_unid_desp::int AS varchar) || p_unidad
               ELSE ''
        END;
END;
$function$;
