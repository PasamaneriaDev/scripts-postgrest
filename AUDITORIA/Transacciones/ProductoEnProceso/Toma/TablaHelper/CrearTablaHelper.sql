-- drop function public.crea_tabla_copia_fisica(esquema_tabla_original varchar, tabla_copia varchar);

CREATE OR REPLACE FUNCTION public.crea_tabla_copia_fisica(esquema_tabla_original varchar, tabla_copia varchar,
                                                          se_creo OUT boolean)
    RETURNS boolean
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_sql varchar;
BEGIN
    IF NOT EXISTS (SELECT
                   FROM information_schema.tables
                   WHERE table_schema = 'public'
                     AND table_name = tabla_copia) THEN
        v_sql = 'CREATE TABLE public.' || tabla_copia || ' ( ' ||
                '	LIKE ' || esquema_tabla_original || ' INCLUDING ALL ' ||
                ');';

        EXECUTE v_sql;
        se_creo := TRUE;
    ELSE
        se_creo := FALSE;
    END IF;
END;
$function$;

select *
from public.crea_tabla_copia_fisica('control_inventarios.ajustes', '_3191_analista');


select *
from public._3191_analista