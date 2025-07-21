CREATE OR REPLACE FUNCTION auditoria.ajuste_toma_prod_proc_crea_tabla_resp(tabla_nombre varchar,
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
                     AND table_name = tabla_nombre) THEN
        v_sql = 'CREATE TABLE public.' || tabla_nombre || ' ( ' ||
                '    id_public serial, ' ||
                '    item varchar(15) NOT NULL, ' ||
                '    costo numeric(11,5) DEFAULT 0, ' ||
                '    costo_nuevo numeric(11,5) DEFAULT 0, ' ||
                '    orden varchar(15), ' ||
                '    cantidad numeric(12,3) DEFAULT 0, ' ||
                '    conos numeric(4) DEFAULT 0, ' ||
                '    tara numeric(12,3) DEFAULT 0, ' ||
                '    cajon numeric(12,3) DEFAULT 0, ' ||
                '    constante numeric(12,3) DEFAULT 0, ' ||
                '    muestra varchar(255), ' ||
                '    cantidad_ajuste numeric(12,3) DEFAULT 0, ' ||
                '    bodega varchar(3) NOT NULL, ' ||
                '    ubicacion varchar(4), ' ||
                '    documento varchar(10) NOT NULL ' ||
                ');';

        EXECUTE v_sql;
        se_creo := TRUE;
    ELSE
        se_creo := FALSE;
    END IF;
END ;
$function$;
