CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas(p_params text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    p_fecha_inicial    date;
    p_fecha_final      date;
    p_item_inicial     text;
    p_item_final       text;
    p_cliente_inicial  text;
    p_cliente_final    text;
    p_linea            text;
    p_familia          text;
    p_agent_bods       text[];
    p_tipo_ventas      text;
    p_tipo_reporte     text;
    p_es_tot_cliente   boolean;
    p_es_tot_agente    boolean;
    p_con_pedidos      boolean;
    p_con_bodegas      boolean;
    p_con_precios      boolean;
    p_con_estadisticas boolean;
    p_con_componentes  boolean;
    query              text;
    where_basic        text;
    cols_basic_item    text;
    cols_basic_sums    text;
    cols_extra_sums    text = '';
    columns_mayorista  text;
    group_by_mayorista text;
    query_mayorista    text;
    where_mayorista    text;
    columns_p_venta    text;
    group_by_p_venta   text;
    query_p_venta      text;
    where_p_venta      text;
BEGIN
    /*
    p_tipo_ventas:
        M = MAYORISTAS
        P = PUNTO DE VENTA
        T = TODO
    p_tipo_reporte:
        R = RESUMIDO
        D = DETALLADO

    -- Notas:
    - Si es p_tipo_ventas = 'T', no puede ser Totalizado
    */
    SELECT fecha_inicial,
           fecha_final,
           item_inicial,
           item_final,
           cliente_inicial,
           cliente_final,
           linea,
           familia,
           codigos_agentes_bodegas,
           tipo_ventas,
           tipo_reporte,
           CASE WHEN tipo_ventas = 'T' THEN FALSE ELSE es_tot_cliente END AS es_tot_cliente,
           CASE WHEN tipo_ventas = 'T' THEN FALSE ELSE es_tot_agente END  AS es_tot_agente,
           con_pedidos,
           con_bodegas,
           con_precios,
           con_estadisticas,
           con_componentes
    INTO p_fecha_inicial,
        p_fecha_final,
        p_item_inicial,
        p_item_final,
        p_cliente_inicial,
        p_cliente_final,
        p_linea,
        p_familia,
        p_agent_bods,
        p_tipo_ventas,
        p_tipo_reporte,
        p_es_tot_cliente,
        p_es_tot_agente,
        p_con_pedidos,
        p_con_bodegas,
        p_con_precios,
        p_con_estadisticas,
        p_con_componentes
    FROM JSONB_TO_RECORD(p_params::jsonb) AS t (fecha_inicial date,
                                                fecha_final date,
                                                item_inicial text,
                                                item_final text,
                                                cliente_inicial text,
                                                cliente_final text,
                                                linea text,
                                                familia text,
                                                codigos_agentes_bodegas text,
                                                tipo_ventas text,
                                                tipo_reporte text,
                                                es_tot_cliente boolean,
                                                es_tot_agente boolean,
                                                con_pedidos boolean,
                                                con_bodegas boolean,
                                                con_precios boolean,
                                                con_estadisticas boolean,
                                                con_componentes boolean);

    cols_basic_item = 'i.item, ' ||
                      'i.descripcion, ' ||
                      'i.unidad_medida, ' ||
                      'i.familia, ' ||
                      'i.linea, ' ||
                      'i.creacion_fecha, ' ||
                      'i.codigo_rotacion, ' ||
                      'i.ultima_venta, ' ||
                      'i.existencia, ' ||
                      'i.peso, ' ||
                      'sum(fd.cantidad * fd.costo) as vtacosto, ' ||
                      'sum(fd.cantidad * i.peso) as vtakilo ';

    cols_basic_sums = 'sum(fd.cantidad * fd.costo) as vtacosto, ' ||
                      'sum(fd.cantidad * i.peso) as vtakilo ';

    where_basic = FORMAT('fd.fecha BETWEEN %1$L AND %2$L ' ||
                         'AND ((fd.item >= %3$L OR %3$L = '''') ' ||
                         'AND (fd.item <= %4$L OR %4$L = '''')) ' ||
                         'AND (i.linea = %5$L OR %5$L = '''') ' ||
                         'AND (i.familia = %6$L OR %6$L = '''') ',
                         p_fecha_inicial, p_fecha_final, p_item_inicial, p_item_final,
                         p_linea, p_familia);

    /************************************************************************/
    -- MAYORISTA
    /************************************************************************/

    IF p_tipo_ventas = 'M' OR p_tipo_ventas = 'T' THEN

        where_mayorista := where_basic ||
                           FORMAT('AND (fd.vendedor = ANY(%1$L) or %1$L = ''{}'' )' ||
                                  'AND ((fd.cliente >= %2$L OR %2$L = '''') ' ||
                                  'AND (fd.cliente <= %3$L OR %3$L = '''')) ',
                                  p_agent_bods, p_cliente_inicial, p_cliente_final);

        cols_extra_sums = ', sum(fd.total_precio - coalesce(fd.descuento_etatex, 0)) as vtaprecio_may, ' ||
                          'sum(fd.cantidad) as cantidad_may ';

        IF p_tipo_ventas = 'T' THEN
            cols_extra_sums = cols_extra_sums || ', 0 as vtaprecio_alm, ' ||
                              '0 as cantidad_alm ';
        END IF;

        IF p_tipo_ventas = 'M' AND p_tipo_reporte = 'D' THEN
            columns_mayorista = cols_basic_item || cols_extra_sums;
            group_by_mayorista = 'i.item';
        ELSEIF p_tipo_ventas = 'M' AND p_tipo_reporte = 'R' THEN
            columns_mayorista = cols_basic_sums || cols_extra_sums;
            group_by_mayorista = '1';
        ELSE
            columns_mayorista = cols_basic_item || cols_extra_sums;
            group_by_mayorista = 'i.item';
        END IF;

        IF NOT p_es_tot_agente AND NOT p_es_tot_cliente THEN
            columns_mayorista = columns_mayorista;
        ELSEIF p_es_tot_agente AND NOT p_es_tot_cliente THEN
            group_by_mayorista = 'r.codigo, r.descripcion, ' || group_by_mayorista;
            columns_mayorista = 'r.codigo as vendedor, r.descripcion AS nombre_vendedor, ' || columns_mayorista;
        ELSEIF NOT p_es_tot_agente AND p_es_tot_cliente THEN
            group_by_mayorista = 'c.codigo, ' || group_by_mayorista;
            columns_mayorista = 'c.codigo as cliente, ' ||
                                'TRIM(REGEXP_REPLACE(c.nombre, E''[\n\r\t\s]+'', '' ''))::varchar      AS nombre_cliente, ' ||
                                'c.ciudad, ' ||
                                'c.telefono1, ' ||
                                'c.terminos_pago, ' || columns_mayorista;
        ELSEIF p_es_tot_agente AND p_es_tot_cliente THEN
            group_by_mayorista = 'r.codigo, r.descripcion, c.codigo, ' || group_by_mayorista;
            columns_mayorista = 'r.codigo as vendedor, ' ||
                                'r.descripcion AS nombre_vendedor, ' ||
                                'c.codigo as cliente, ' ||
                                'TRIM(REGEXP_REPLACE(c.nombre, E''[\n\r\t\s]+'', '' ''))::varchar      AS nombre_cliente, ' ||
                                'c.ciudad, ' ||
                                'c.telefono1, ' ||
                                'c.terminos_pago, ' || columns_mayorista;
        END IF;

        query_mayorista := FORMAT('SELECT %s' ||
                                  'FROM cuentas_cobrar.facturas_detalle fd ' ||
                                  '         LEFT JOIN sistema.reglas r ON fd.vendedor = r.codigo AND regla = ''SLSPERS'' ' ||
                                  '         LEFT JOIN control_inventarios.items i ON fd.item = i.item ' ||
                                  '         LEFT JOIN cuentas_cobrar.clientes c ON fd.cliente = c.codigo ' ||
                                  'WHERE fd.vendedor <> ''SG'' ' ||
                                  '  AND LEFT(fd.referencia, 1) NOT IN (''X'', ''P'') ' ||
                                  '  AND coalesce(fd.status, '''') <> ''V'' ' ||
                                  '  AND (((i.es_fabricado OR i.item IS NULL) AND ' ||
                                  '       SUBSTRING(i.item FROM 1 FOR 1) IN (''1'', ''2'', ''3'', ''4'', ''5'', ''6'', ''7'', ''8'', ''9'', ''0'', ''B'', ''Z'')) OR ' ||
                                  '       (SUBSTRING(i.item FROM 1 FOR 1) NOT IN (''1'', ''2'', ''3'', ''4'', ''5'', ''6'', ''7'', ''8'', ''9'', ''0'', ''Z'', ''B'', ''X'') ' ||
                                  '           AND ' ||
                                  '        (SUBSTRING(fd.codigo_venta FROM 1 FOR 1) IN (''V'', ''D'', ''O'') OR ' ||
                                  '         SUBSTRING(fd.codigo_venta FROM 1 FOR 3) IN (''FAE'', ''FDE''))) OR ' ||
                                  '       SUBSTRING(i.item FROM 1 FOR 2) IN (''1U'', ''55'')) ' ||
                                  '  AND fd.codigo_venta NOT IN (''GDC'', ''GDQ'') ' ||
                                  '  AND LEFT(fd.item, 4) != ''CONO'' ' ||
                                  '  AND %s ' ||
                                  'GROUP BY %s ', columns_mayorista, where_mayorista, group_by_mayorista);
    END IF;

    /************************************************************************/
    -- PUNTOS DE VENTA
    /************************************************************************/

    IF p_tipo_ventas = 'P' OR p_tipo_ventas = 'T' THEN
        where_p_venta := where_basic ||
                         FORMAT('AND (ib.bodega = ANY(%1$L) or %1$L = ''{}'' )',
                                p_agent_bods);

        IF p_tipo_ventas = 'T' THEN
            cols_extra_sums = ', 0 as vtaprecio_may, ' ||
                              '0 as cantidad_may ';
        END IF;

        cols_extra_sums = cols_extra_sums ||
                          ', sum(fd.total_precio - coalesce(fd.valor_descuento_adicional, 0)) as vtaprecio_alm, ' ||
                          'sum(fd.cantidad) as cantidad_alm ';


        IF p_tipo_ventas = 'P' AND p_tipo_reporte = 'D' THEN
            columns_p_venta = 'ib.bodega, ' ||
                              'ib.descripcion as nombre_bodega,' ||
                              'ib.provincia,' ||
                              'right(ib.region,3) as region, ' || cols_basic_item || cols_extra_sums;
            group_by_p_venta = 'ib.bodega, i.item';
        ELSEIF p_tipo_ventas = 'P' AND p_tipo_reporte = 'R' THEN
            columns_p_venta = 'ib.bodega, ' ||
                              'ib.descripcion as nombre_bodega,' ||
                              'ib.provincia,' ||
                              'right(ib.region,3) as region, ' || cols_basic_sums || cols_extra_sums;
            group_by_p_venta = 'ib.bodega';
        ELSE
            columns_p_venta = cols_basic_item || cols_extra_sums;
            group_by_p_venta = 'i.item';
        END IF;

        query_p_venta := FORMAT('SELECT %s' ||
                                'FROM puntos_venta.facturas_detalle fd ' ||
                                '         JOIN control_inventarios.id_bodegas ib on fd.bodega = ib.bodega ' ||
                                '         LEFT JOIN control_inventarios.items i ON fd.item = i.item ' ||
                                'WHERE ((COALESCE(fd.status, '''') <> ''ANULADA'' AND i.es_stock AND i.es_fabricado) ' ||
                                '  OR (LEFT(fd.codigo_venta, 1) IN (''V'', ''D'', ''O'') AND fd.codigo_inventario = ''PRT'') ' ||
                                '  OR LEFT(fd.item, 1) = ''Z'') ' ||
                                '  AND %s ' ||
                                'GROUP BY %s ', columns_p_venta, where_p_venta, group_by_p_venta);

    END IF;

    -- Generar Temporal
    IF p_tipo_ventas = 'T' THEN
        IF p_tipo_reporte = 'R' THEN
            QUERY := FORMAT('' ||
                            ' DROP TABLE IF EXISTS reporte_general_ventas_temp;' ||
                            'CREATE TEMP TABLE reporte_general_ventas_temp AS (' ||
                            '  select  ' ||
                            '    sum(r1.vtacosto) as vtacosto, ' ||
                            '    sum(r1.vtakilo) as vtakilo, ' ||
                            '    sum(r1.vtaprecio_may) as vtaprecio_may, ' ||
                            '    sum(r1.cantidad_may) as cantidad_may, ' ||
                            '    sum(r1.vtaprecio_alm) as vtaprecio_alm, ' ||
                            '    sum(r1.cantidad_alm) as cantidad_alm ' ||
                            '  from (%s union all %s) as r1)', query_mayorista, query_p_venta);
        ELSE
            QUERY := FORMAT('' ||
                            ' DROP TABLE IF EXISTS reporte_general_ventas_temp;' ||
                            'CREATE TEMP TABLE reporte_general_ventas_temp AS (' ||
                            '  SELECT r1.item, ' ||
                            '       r1.descripcion, ' ||
                            '       r1.unidad_medida, ' ||
                            '       r1.familia, ' ||
                            '       r1.linea, ' ||
                            '       r1.creacion_fecha, ' ||
                            '       r1.codigo_rotacion, ' ||
                            '       r1.ultima_venta, ' ||
                            '       r1.existencia, ' ||
                            '       r1.peso, ' ||
                            '       SUM(r1.vtacosto)      AS vtacosto, ' ||
                            '       SUM(r1.vtakilo)       AS vtakilo, ' ||
                            '       SUM(r1.vtaprecio_may) AS vtaprecio_may, ' ||
                            '       SUM(r1.cantidad_may)  AS cantidad_may, ' ||
                            '       SUM(r1.vtaprecio_alm) AS vtaprecio_alm, ' ||
                            '       SUM(r1.cantidad_alm)  AS cantidad_alm ' ||
                            'FROM (%s union all %s) AS r1 ' ||
                            'GROUP BY r1.item, ' ||
                            '         r1.descripcion, ' ||
                            '         r1.unidad_medida, ' ||
                            '         r1.familia, ' ||
                            '         r1.linea, ' ||
                            '         r1.creacion_fecha, ' ||
                            '         r1.codigo_rotacion, ' ||
                            '         r1.ultima_venta, ' ||
                            '         r1.existencia, ' ||
                            '         r1.peso)', query_mayorista, query_p_venta);
        END IF;
    ELSE
        QUERY := FORMAT('DROP TABLE IF EXISTS reporte_general_ventas_temp;' ||
                        'CREATE TEMP TABLE reporte_general_ventas_temp AS (' ||
                        '%s)', CASE WHEN p_tipo_ventas = 'M' THEN query_mayorista ELSE query_p_venta END);
    END IF;

    IF query = '' THEN
        RAISE EXCEPTION 'No se ha generado la Tabla Temporal para el Reporte...';
    END IF;

    EXECUTE query;

    IF p_tipo_reporte = 'D' THEN

        IF p_con_bodegas THEN
            ALTER TABLE reporte_general_ventas_temp
                ADD COLUMN demanda999 numeric,
                ADD COLUMN demanda000 numeric,
                ADD COLUMN demanda100 numeric,
                ADD COLUMN demanda001 numeric,
                ADD COLUMN demanda101 numeric,
                ADD COLUMN demanda131 numeric,
                ADD COLUMN exist005   numeric;

            UPDATE reporte_general_ventas_temp r
            SET demanda999 = bf.demanda999,
                demanda000 = bf.demanda000,
                demanda100 = bf.demanda100,
                demanda001 = bf.demanda001,
                demanda101 = bf.demanda101,
                demanda131 = bf.demanda131,
                exist005   = bf.exist005
            FROM (SELECT b.item,
                         MAX(CASE WHEN b.bodega = '999' THEN b.buffer END)     AS demanda999,
                         MAX(CASE WHEN b.bodega = '000' THEN b.buffer END)     AS demanda000,
                         MAX(CASE WHEN b.bodega = '100' THEN b.buffer END)     AS demanda100,
                         MAX(CASE WHEN b.bodega = '001' THEN b.buffer END)     AS demanda001,
                         MAX(CASE WHEN b.bodega = '101' THEN b.buffer END)     AS demanda101,
                         MAX(CASE WHEN b.bodega = '131' THEN b.buffer END)     AS demanda131,
                         MAX(CASE WHEN b.bodega = '005' THEN b.existencia END) AS exist005
                  FROM control_inventarios.bodegas b
                  WHERE b.bodega IN ('999', '000', '100', '001', '101', '131', '005')
                  GROUP BY b.item) bf
            WHERE r.item = bf.item;
        END IF;

        IF p_con_precios THEN
            ALTER TABLE reporte_general_ventas_temp
                ADD COLUMN preciodis numeric,
                ADD COLUMN preciomay numeric,
                ADD COLUMN preciopvp numeric;

            UPDATE reporte_general_ventas_temp r
            SET preciodis = COALESCE(p.dis_precio, 0),
                preciomay = COALESCE(p.may_precio, 0),
                preciopvp = COALESCE(p.pvp_precio, 0)
            FROM (SELECT item,
                         MAX(CASE WHEN tipo = 'DIS' THEN precio END) AS dis_precio,
                         MAX(CASE WHEN tipo = 'MAY' THEN precio END) AS may_precio,
                         MAX(CASE WHEN tipo = 'PVP' THEN precio END) AS pvp_precio
                  FROM control_inventarios.precios
                  WHERE tipo IN ('DIS', 'MAY', 'PVP')
                  GROUP BY item) p
            WHERE r.item = p.item;
        END IF;

        IF p_con_componentes AND LEFT(p_item_inicial, 1) = 'B' AND LEFT(p_item_final, 1) = 'B' THEN
            ALTER TABLE reporte_general_ventas_temp
                ADD COLUMN componente VARCHAR,
                ADD COLUMN componeexi numeric,
                ADD COLUMN componedi  numeric;

            UPDATE reporte_general_ventas_temp r
            SET componente = e.componente,
                componeexi = COALESCE(b.existencia, 0),
                componedi  = COALESCE(b.buffer, 0)
            FROM lista_materiales.estructuras e
                     LEFT JOIN control_inventarios.bodegas b ON e.componente = b.item AND b.bodega = 'MTB'
            WHERE e.item = r.item
              AND e.componente LIKE '4%';
        END IF;

        -- Agregar Pedidos si requiere
        IF p_con_pedidos THEN
            ALTER TABLE reporte_general_ventas_temp
                ADD COLUMN ped_colocad numeric,
                ADD COLUMN ped_pendien numeric;

            UPDATE reporte_general_ventas_temp r
            SET ped_pendien = pg.ped_pendien
            FROM (SELECT pd.item, COALESCE(SUM(pd.cantidad_pendiente), 0) AS ped_pendien
                  FROM ordenes_venta.pedidos_detalle pd
                  WHERE pd.estado NOT IN ('C', 'V', '-', 'X')
                  GROUP BY pd.item) AS pg
            WHERE pg.item = r.item;

            UPDATE reporte_general_ventas_temp r
            SET ped_colocad = pg.ped_colocad
            FROM (SELECT pd.item, COALESCE(SUM(pd.cantidad_pendiente + pd.cantidad_despachada), 0) AS ped_colocad
                  FROM ordenes_venta.pedidos_detalle pd
                  WHERE pd.estado NOT IN ('C', 'V', '-', 'X')
                    AND pd.fecha_pedido BETWEEN p_fecha_inicial AND p_fecha_final
                  GROUP BY pd.item) AS pg
            WHERE pg.item = r.item;
        END IF;
    END IF;
END;
$function$;