CREATE OR REPLACE FUNCTION control_inventarios.inventarios_proceso_condicion_bodega(p_bodega character varying)
    RETURNS TABLE
            (
                condicion_primera text,
                condicion_segunda text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_condicion_primera text;
    v_condicion_segunda text;
BEGIN
    v_condicion_primera = FORMAT('left(aj.ubicacion,1) = left(%L,1)', p_bodega);
    v_condicion_segunda = 'true';

    IF p_bodega = 'M' THEN -- Materias Primas
        v_condicion_segunda = 'left(aj.bodega,1) = ''M''';
    ELSIF p_bodega = 'G' THEN -- Confecciones
        v_condicion_segunda = 'left(aj.bodega,1) = any(''{G,2,3,A,B,M}''::text[]) ' ||
                              'AND aj.ubicacion <> ''GS''';
    ELSIF p_bodega = 'B' THEN -- Crudos
        v_condicion_segunda = 'left(aj.bodega,1) = ''B''';
    ELSIF p_bodega = 'A' THEN -- Hilandería
        v_condicion_primera = 'existencia <> 0';
        v_condicion_segunda = 'left(aj.bodega,1) = ''A''';
    ELSIF p_bodega = 'J' THEN -- Tintorería
        v_condicion_segunda = 'left(aj.bodega,2) = any(''{MD,MI,J}''::text[]) ' ||
                              'AND left(aj.ubicacion,1) = ''J''';
    ELSIF p_bodega = 'GS' THEN -- Serigrafía
        v_condicion_segunda = 'left(aj.bodega,2) = ''MD'' ' ||
                              'AND left(aj.ubicacion,2) = ''GS''';
    ELSIF p_bodega = 'P' THEN -- Piezas
        v_condicion_primera = 'aj.existencia <> 0';
        v_condicion_segunda = 'aj.bodega = ''P'' ' ||
                              'AND (left(aj.ubicacion,1) = ''P'' OR aj.ubicacion = ''0000'')';
    ELSIF p_bodega = 'I' THEN -- Hilos de coser
        v_condicion_primera = 'aj.existencia <> 0';
        v_condicion_segunda = 'aj.bodega = ''I  '' ' ||
                              'AND (LEFT(aj.ubicacion,1) = ''I'' OR aj.ubicacion = ''0000'')';
    END IF;

    RETURN QUERY SELECT v_condicion_primera, v_condicion_segunda;
END

$function$
;