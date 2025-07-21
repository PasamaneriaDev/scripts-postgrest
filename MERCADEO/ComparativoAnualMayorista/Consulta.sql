-- DROP FUNCTION cuentas_cobrar.clientes_ventas_por_anio_pivot(in int4, in int4, in bool, out text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.clientes_ventas_por_anio_pivot(p_anio_inicial integer, p_anio_final integer,
                                                                         p_agente varchar, p_agrupa_por_agente boolean,
                                                                         OUT o_respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_sql          TEXT;
    v_anio         INT;
    v_fecha_inicio DATE;
    v_fecha_fin    DATE;
    v_col_vendedor text;
BEGIN
    IF p_anio_final < p_anio_inicial THEN
        RAISE EXCEPTION 'El año final (%) no puede ser menor que el año inicial (%)', p_anio_final, p_anio_inicial;
    END IF;

    v_fecha_inicio := MAKE_DATE(p_anio_inicial, 1, 1);
    v_fecha_fin := MAKE_DATE(p_anio_final, 12, 31);

    v_col_vendedor = CASE WHEN p_agrupa_por_agente THEN 'fc.vendedor' ELSE 'c.vendedor' END;

    v_sql := '
		DROP TABLE IF EXISTS _clientes_ventas_pivot_temp ;
        create temp table _clientes_ventas_pivot_temp as
        SELECT
            ' || CASE WHEN p_agrupa_por_agente THEN ' fc.vendedor ' ELSE '''''::varchar' END || ' as agente_factura,
            c.vendedor    AS agente_actual,
            c.terminos_pago as terminos,
            c.codigo AS cliente_codigo,
            c.ciudad,
            c.nombre AS cliente_nombre';

    FOR v_anio IN p_anio_inicial..p_anio_final
        LOOP
            v_sql := v_sql || ',
            SUM(CASE WHEN EXTRACT(YEAR FROM fc.fecha) = ' || v_anio ||
                     ' THEN fc.monto_total - fc.iva ELSE 0 END) AS "' || v_anio || '"';
        END LOOP;

    v_sql := v_sql || '
        FROM cuentas_cobrar.facturas_cabecera fc
        JOIN cuentas_cobrar.clientes c ON c.codigo = fc.cliente
        WHERE fc.status IS NULL
            AND (fc.tipo_documento IS NULL OR fc.tipo_documento = ''C'')
            AND fc.fecha BETWEEN ''' || v_fecha_inicio || ''' AND ''' || v_fecha_fin || '''
            AND (fc.vendedor = ''' || p_agente || ''' OR ''' || p_agente || ''' = '''')
        GROUP BY ' || v_col_vendedor || ', c.codigo
        ORDER BY agente_factura, agente_actual, c.codigo, c.nombre;';

    EXECUTE v_sql;

    o_respuesta = 'Se genero la tabla temporal: _clientes_ventas_pivot_temp';
END;
$function$
;
