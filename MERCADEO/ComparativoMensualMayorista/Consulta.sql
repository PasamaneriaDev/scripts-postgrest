-- DROP FUNCTION cuentas_cobrar.reporte_comparativo_mensual_bi_anual(integer, integer, varchar, boolean);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_comparativo_mensual_bi_anual(p_anio_inicial integer,
                                                                               p_anio_final integer, p_vendedor varchar,
                                                                               p_es_agrupado_agente boolean)
    RETURNS table
            (
                vendedor_factura varchar,
                nombre_vendedor  varchar,
                vendedor_actual  varchar,
                codigo_mayorista varchar,
                nombre_mayorista varchar,
                enero1           numeric,
                febrero1         numeric,
                marzo1           numeric,
                abril1           numeric,
                mayo1            numeric,
                junio1           numeric,
                julio1           numeric,
                agosto1          numeric,
                septiembre1      numeric,
                octubre1         numeric,
                noviembre1       numeric,
                diciembre1       numeric,
                enero2           numeric,
                febrero2         numeric,
                marzo2           numeric,
                abril2           numeric,
                mayo2            numeric,
                junio2           numeric,
                julio2           numeric,
                agosto2          numeric,
                septiembre2      numeric,
                octubre2         numeric,
                noviembre2       numeric,
                diciembre2       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    sql            text;
    v_col_vendedor varchar;
BEGIN
    IF p_es_agrupado_agente THEN
        v_col_vendedor := 'fc.vendedor';
    ELSE
        v_col_vendedor := 'cl.vendedor';
    END IF;

    sql = FORMAT('SELECT ' || CASE WHEN p_es_agrupado_agente THEN ' fc.vendedor ' ELSE '''''::varchar' END || '      AS vendedor_factura,
               ' || CASE WHEN p_es_agrupado_agente THEN ' ve.descripcion ' ELSE '''''::varchar' END || ' AS nombre_vendedor,
               cl.vendedor    AS vendedor_actual,
               cl.codigo      AS codigo_mayorista,
               cl.nombre      AS nombre_mayorista,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-01'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS enero1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-02'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS febrero1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-03'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS marzo1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-04'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS abril1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-05'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS mayo1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-06'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS junio1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-07'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS julio1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-08'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS agosto1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-09'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS septiembre1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-10'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS octubre1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-11'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS noviembre1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %1$L || ''-12'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS diciembre1,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-01'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS enero2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-02'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS febrero2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-03'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS marzo2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-04'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS abril2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-05'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS mayo2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-06'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS junio2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-07'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS julio2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-08'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS agosto2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-09'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS septiembre2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-10'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS octubre2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-11'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS noviembre2,
               SUM(CASE WHEN TO_CHAR(fc.fecha, ''YYYY-MM'') = %2$L || ''-12'' THEN (fc.monto_total - fc.iva) ELSE 0 END) AS diciembre2
        FROM cuentas_cobrar.facturas_cabecera fc
                 JOIN cuentas_cobrar.clientes cl ON cl.codigo = fc.cliente
                 LEFT JOIN sistema.reglas ve ON ve.codigo = %4$s AND regla = ''SLSPERS''
        WHERE (fc.vendedor = %3$L OR %3$L = '''')
          AND (EXTRACT(YEAR FROM fc.fecha) = %2$L
            OR EXTRACT(YEAR FROM fc.fecha) = %1$L)
          AND fc.status IS NULL
          AND (fc.tipo_documento IS NULL OR fc.tipo_documento = ''C'')
        GROUP BY %4$s, ve.descripcion, cl.codigo
        ORDER BY %4$s, cl.nombre ASC;', p_anio_inicial, p_anio_final, p_vendedor, v_col_vendedor);

    RAISE NOTICE 'SQL: %', sql;
    RETURN QUERY
        EXECUTE sql;
END;
$function$
;

SELECT *
FROM cuentas_cobrar.reporte_comparativo_mensual_bi_anual(2024, 2025, '', TRUE)
;


