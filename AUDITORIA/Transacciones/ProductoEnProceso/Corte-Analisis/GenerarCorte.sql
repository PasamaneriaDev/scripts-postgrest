CREATE OR REPLACE FUNCTION control_inventarios.corte_inventario_proceso_guardar(p_bodega character varying)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_condicion_primera text;
    v_condicion_segunda text;
    v_sql_delete        text;
    v_sql_insert        text;
BEGIN
    SELECT condicion_primera, condicion_segunda
    INTO v_condicion_primera, v_condicion_segunda
    FROM control_inventarios.inventarios_proceso_condicion_bodega(p_bodega);

    v_sql_delete = FORMAT('DELETE FROM control_inventarios.ubicaciones_corte_inventario ' ||
                          'WHERE bodega_proceso = %L;', p_bodega);

    -- Borrar registros de la bodega seleccionada de manera segura
    EXECUTE v_sql_delete;

    -- Insertar los nuevos valores
    v_sql_insert = FORMAT(
            'INSERT INTO control_inventarios.ubicaciones_corte_inventario (bodega, ubicacion, item, existencia, transito, creacion_usuario, creacion_fecha, creacion_hora, bodega_proceso) ' ||
            'SELECT aj.bodega, aj.ubicacion, aj.item, aj.existencia, aj.transito, aj.creacion_usuario, aj.creacion_fecha, aj.creacion_hora, %L ' ||
            'FROM control_inventarios.ubicaciones aj ' ||
            'WHERE %s AND %s;', p_bodega, v_condicion_primera, v_condicion_segunda);
    EXECUTE v_sql_insert;

END
$function$
;
