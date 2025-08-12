-- DROP FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(varchar, varchar, varchar, varchar, varchar);

-- drop function puntos_venta.reporte_ventas_x_kilo_unidad_dolar(p_item_inicial varchar, p_item_final varchar, p_fecha_inicial varchar, p_fecha_final varchar);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_x_kilo_unidad_dolar(
    p_item_inicial varchar,
    p_item_final varchar,
    p_fecha_inicial varchar,
    p_fecha_final varchar
)
    RETURNS TABLE
            (
                linea               text,
                descripcion_seccion text,
                unidad_medida       varchar,
                cantidad            numeric,
                peso                numeric,
                precio              numeric
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_query      text;
    v_linea      text;
BEGIN

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
            ' || v_linea || ' AS clave,

            END AS descripcion_seccion,
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
    v_query := FORMAT(v_query || ' UNION all ' || v_query,
                      'puntos_venta.facturas_detalle', 'cuentas_cobrar.facturas_detalle');
    v_query := v_query || ' ORDER BY linea ASC, unidad_medida ASC';

    v_query = 'with reporte_ventas as (' || v_query || ')
        SELECT linea, descripcion_seccion, unidad_medida, SUM(cantidad) AS cantidad,
               SUM(peso) AS peso, SUM(precio) AS precio
        FROM reporte_ventas
        group by linea, unidad_medida, descripcion_seccion
        order by linea, unidad_medida
        ';

    RETURN QUERY EXECUTE v_query;
END ;
$$;

SELECT *
FROM puntos_venta.reporte_ventas_x_kilo_unidad_dolar(
        'B',
        'BZ',
        '2025-07-01',
        '2025-07-31'
     );




