-- DROP FUNCTION auditoria.genera_existencia_bodega_temp(in varchar, in varchar, in varchar, in varchar, in bool, in bool, in bool, in bool, in varchar, in varchar, in varchar, in varchar, out varchar);

CREATE OR REPLACE FUNCTION auditoria.genera_existencia_bodega_temp(p_bodegas character varying,
                                                                   p_item_inicial character varying,
                                                                   p_item_final character varying,
                                                                   p_periodo character varying, p_negativos boolean,
                                                                   p_por_ubicac boolean, p_con_cero boolean,
                                                                   p_val_costo boolean, p_ubicacion character varying,
                                                                   p_existencia character varying,
                                                                   p_tipo character varying,
                                                                   p_articulo character varying,
                                                                   OUT respuesta character varying)
    RETURNS character varying
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_condicion    varchar;
    v_tabla        varchar;
    v_real_periodo varchar;
    v_columnas     varchar;
    v_es_actual    boolean;
    v_col_comp     varchar;
    query          varchar;
BEGIN
    /***
        p_existencia: 'D' - Disponible
                      'T' - Total
        p_articulo: 'PR' - Propio
                    'CO' - Consignacion
                    'NO' - No Venta
                    'TO' - Todos
    ***/

    /*** ARMAR LA CONDICIONAL ***/
    IF LEFT(p_articulo, 2) = 'PR' THEN
        v_condicion = ' i.es_fabricado AND i.es_vendible ';
    ELSIF LEFT(p_articulo, 2) = 'CO' THEN
        v_condicion = ' not i.es_fabricado AND i.es_vendible ';
    ELSEIF LEFT(p_articulo, 2) = 'NO' THEN
        v_condicion = ' not i.es_fabricado ';
    ELSE
        v_condicion = ' TRUE ';
    END IF;

    v_real_periodo = CASE
                         WHEN p_periodo = ''
                             THEN TO_CHAR(CURRENT_DATE, 'YYYYMM')
                         ELSE p_periodo END;
    v_es_actual = v_real_periodo = TO_CHAR(CURRENT_DATE, 'YYYYMM');

    v_condicion = v_condicion ||
                  CASE
                      WHEN COALESCE(p_bodegas, '') <> '' THEN ' AND b.bodega = any (''{' || p_bodegas || '}''::TEXT[]) '
                      ELSE '' END;

    v_condicion = v_condicion || ' and b.item >= ''' || p_item_inicial || ''' and b.item <= ''' || p_item_final || '''';

    IF NOT (p_bodegas LIKE '%C%' OR p_bodegas LIKE '%D%' OR p_bodegas LIKE '%H%' OR p_bodegas LIKE '%MD%' OR
            p_bodegas LIKE '%MI%' OR p_bodegas LIKE '%MR%' OR
            p_bodegas LIKE '%MB%' OR p_bodegas LIKE '%079%' OR p_bodegas LIKE '%R%' OR p_bodegas LIKE '%S%' OR
            p_bodegas LIKE '%U%' OR p_bodegas LIKE '%MTB%') AND p_tipo <> '' THEN
        v_condicion = v_condicion || ' AND i.codigo_rotacion  = any (''{' || p_tipo || '}''::TEXT[]) ';
    END IF;

    -- Columna de Comprometido (lsoaloc)
    v_col_comp = CASE
                     WHEN v_es_actual THEN
                         CASE
                             WHEN p_por_ubicac THEN ' b.comprometido_despacho '
                             ELSE ' b.pedidos_clientes '
                             END
                     ELSE 'b.pedidos' END;

    -- Condiciones de Existencia
    IF v_es_actual THEN -- Si es periodo actual
        v_tabla = CASE
                      WHEN p_por_ubicac THEN 'control_inventarios.ubicaciones'
                      ELSE 'control_inventarios.bodegas' END;

        IF p_negativos THEN
            v_condicion = v_condicion ||
                          ' AND b.existencia < 0' || CASE
                                                         WHEN p_ubicacion <> '' AND p_por_ubicac
                                                             THEN ' and b.ubicacion = ' || p_ubicacion
                                                         ELSE '' END;
        ELSE
            v_condicion = v_condicion ||
                          ' AND ' || CASE
                                         WHEN LEFT(p_existencia, 1) = 'D'
                                             THEN '(b.existencia <> 0 OR ' || v_col_comp || ' <> 0)'
                                         ELSE
                                             CASE
                                                 WHEN p_con_cero
                                                     THEN 'b.existencia >= 0'
                                                 ELSE 'b.existencia <> 0' END
                              END;
            v_condicion = v_condicion || CASE
                                             WHEN p_ubicacion <> '' AND p_por_ubicac
                                                 THEN ' AND b.ubicacion = ' || p_ubicacion
                                             ELSE '' END;

        END IF;
    ELSE -- Si es periodo historico
        v_tabla = 'control_inventarios.items_historico';

        v_condicion = v_condicion || ' AND b.periodo = ''' || v_real_periodo || '''';
        v_condicion = v_condicion || ' AND b.nivel = ' || CASE WHEN p_por_ubicac THEN '''IQTY''' ELSE '''ILOC''' END;
        v_condicion = v_condicion || ' AND ' ||
                      CASE
                          WHEN p_negativos THEN 'b.existencia < 0'
                          ELSE CASE WHEN p_con_cero THEN 'b.existencia >= 0' ELSE 'b.existencia <> 0' END END;
    END IF;

    v_tabla = v_tabla || ' b JOIN control_inventarios.items i ON b.item = i.item ' ||
              ' JOIN control_inventarios.id_bodegas ib ON b.bodega = ib.bodega ';

    /*** ARMAR LAS COLUMNAS ***/
    -- es_vendible, es_fabricado, es_comprado, descripción bodega.
    v_columnas = 'b.item, i.descripcion, i.unidad_medida, i.codigo_rotacion, ' ||
                 'i.es_vendible, i.es_fabricado, i.es_comprado, i.costo_promedio, ' ||
                 CASE
                     WHEN LEFT(p_existencia, 1) = 'T' THEN ' b.existencia '
                     ELSE ' b.existencia - ' || v_col_comp
                     END || ' as existencia, ' ||
                 CASE
                     WHEN p_val_costo THEN 'i.costo_promedio * b.existencia'
                     ELSE '0' END || '::numeric as valor, ' ||
                 'b.bodega, ib.descripcion as descripcion_bodega, ' ||
                 CASE
                     WHEN p_por_ubicac THEN 'b.ubicacion'
                     ELSE '''''' END || '::varchar as ubicacion, b.transito, ' ||
                 v_col_comp || '::numeric as comprometido ';

    respuesta := '_temp_exist_bod';
    RAISE NOTICE 'respuesta: %, v_tabla: %, v_condicion: %, v_columnas: %',
        respuesta, v_tabla, v_condicion, v_columnas;
    query = '
            DROP TABLE IF EXISTS ' || respuesta || ';
            create temp table ' || respuesta || ' as (
            	SELECT ' || v_columnas || '
                FROM ' || v_tabla || '
                WHERE ' || v_condicion || '
                ORDER BY b.item
            )';

    RAISE NOTICE 'QUERY %', query;
    EXECUTE query;
END ;
$function$
;



SELECT *
FROM auditoria.genera_existencia_bodega_temp('',
                                             '17',
                                             '18',
                                             '',
                                             FALSE,
                                             FALSE,
                                             TRUE,
                                             TRUE,
                                             '',
                                             'D',
                                             '',
                                             'PR');


SELECT *
FROM _temp_exist_bod

-- es_vendible, es_fabricado, es_comprado, costo_promedio,
-- descripcion_bodega