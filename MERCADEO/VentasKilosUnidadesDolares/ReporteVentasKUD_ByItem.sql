-- DROP FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(varchar, varchar, varchar, varchar, varchar);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(
    p_tipo_reporte varchar,
    p_item_inicial varchar,
    p_item_final varchar,
    p_fecha_inicial varchar,
    p_fecha_final varchar
)
    RETURNS TABLE
            (
                linea               text,
                descripcion_seccion text,
                tipo_venta          varchar,
                unidad_medida       varchar,
                cantidad            numeric,
                peso                numeric,
                precio              numeric
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_query          text;
    v_table_name     text;
    v_titulo_reporte text;
    v_linea          text;
BEGIN
    IF p_tipo_reporte = 'PUNTO VENTA' THEN
        v_table_name := 'puntos_venta.facturas_detalle';
        v_titulo_reporte := 'Puntos de Venta';
    ELSIF p_tipo_reporte = 'MAYORISTA' THEN
        v_table_name := 'cuentas_cobrar.facturas_detalle';
        v_titulo_reporte := 'Mayorista';
    ELSE
        v_titulo_reporte := 'Puntos de Venta + Mayorista';
    END IF;

    v_linea = 'CASE
            WHEN LEFT(df.item, 1) <> ''B'' THEN
                CASE
                    WHEN LEFT(df.item, 1) = ''D'' THEN
                        ''1''
                    ELSE
                        LEFT(df.item, 1)
                END
            ELSE
                LEFT(df.item, 5)
        END';

    v_query := '
        SELECT
            ' || v_linea || ' AS linea,
            CASE
                WHEN LEFT(df.item, 1) = ''1'' THEN ''Confecciones''
                WHEN LEFT(df.item, 1) = ''2'' THEN ''Telares''
                WHEN LEFT(df.item, 1) = ''3'' THEN ''Trenzadoras''
                WHEN LEFT(df.item, 1) = ''4'' THEN ''Tintoreria''
                WHEN LEFT(df.item, 1) = ''5'' THEN ''Calcetines''
                WHEN LEFT(df.item, 1) = ''6'' THEN ''Encajes''
                WHEN LEFT(df.item, 1) = ''7'' THEN ''Mallas''
                WHEN LEFT(df.item, 1) = ''9'' THEN ''Seda''
                WHEN LEFT(df.item, 1) = ''B'' THEN ''Hilos B''
                WHEN LEFT(df.item, 1) = ''M'' THEN ''Fundas Almacenes''
                WHEN LEFT(df.item, 1) = ''W'' THEN ''Articulos Promocionales''
                WHEN LEFT(df.item, 1) = ''Z'' THEN ''Desperdicio''
            END AS descripcion_seccion,
            %s AS tipo_venta,
            r1.unidad_medida,
            (df.cantidad) AS cantidad,
            ROUND((r1.peso * df.cantidad), 3) AS peso,
            (df.total_precio) AS precio
        FROM %s df
        LEFT join control_inventarios.items r1 ON df.item = r1.item
        WHERE (df.item >= ''' || p_item_inicial || ''' AND df.item <= ''' || p_item_final || ''')
            AND df.fecha BETWEEN TO_DATE(''' || p_fecha_inicial || ''', ''YYYY-MM-DD'') AND TO_DATE(''' ||
               p_fecha_final || ''', ''YYYY-MM-DD'')
            AND df.status IS NULL
            AND r1.es_vendible = TRUE
            AND r1.es_fabricado = TRUE
            AND LEFT(df.item, 1) != ''Z''';

    -- Si es combinación, construimos una consulta con UNION
    IF p_tipo_reporte NOT IN ('PUNTO VENTA', 'MAYORISTA') THEN
        v_query := FORMAT(v_query || ' UNION all ' || v_query,
                          '''Puntos de Venta''::varchar', 'puntos_venta.facturas_detalle',
                          '''Mayoristas''::varchar', 'cuentas_cobrar.facturas_detalle');
        v_query := v_query || ' ORDER BY linea ASC, tipo_venta ASC, unidad_medida ASC';
    ELSE
        v_query := FORMAT(v_query, '''' || v_titulo_reporte || '''::varchar', v_table_name);
        v_query := v_query || ' ORDER BY linea ASC, unidad_medida ASC';
    END IF;
    v_query = 'with reporte_ventas as (' || v_query || ')
        SELECT linea, descripcion_seccion, tipo_venta, unidad_medida, SUM(cantidad) AS cantidad,
               SUM(peso) AS peso, SUM(precio) AS precio
        FROM reporte_ventas
        group by linea, unidad_medida, descripcion_seccion, tipo_venta
        order by linea, tipo_venta, unidad_medida
        ';

    RETURN QUERY EXECUTE v_query;
END ;
$$;

SELECT *
FROM puntos_venta.reporte_ventas_x_kilo_unidad_dolar(
        'TODO',
        'B',
        'BZ',
        '2025-07-01',
        '2025-07-31'
     );




