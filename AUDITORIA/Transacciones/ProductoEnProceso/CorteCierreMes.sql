-- DROP FUNCTION auditoria.corte_producto_proceso_cierre_mes();

CREATE OR REPLACE FUNCTION auditoria.corte_producto_proceso_cierre_mes()
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    TRUNCATE TABLE inventario_proceso.costos;
    TRUNCATE TABLE inventario_proceso.ubicaciones;
    TRUNCATE TABLE inventario_proceso.bodegas;
    TRUNCATE TABLE inventario_proceso.items;

    INSERT INTO inventario_proceso.items
    (item,
     descripcion,
     codigo_rotacion,
     unidad_medida,
     costo_promedio,
     costo_estandar,
     ultimo_costo,
     existencia,
     transito)
    SELECT item,
           descripcion,
           codigo_rotacion,
           unidad_medida,
           costo_promedio,
           costo_estandar,
           ultimo_costo,
           existencia,
           transito
    FROM control_inventarios.items i
    WHERE LEFT(i.item, 1) NOT IN ('0', '8', 'A', 'C', 'D', 'F', 'H', 'R', 'S', 'T', 'U', 'X', 'Z');

    INSERT INTO inventario_proceso.bodegas
    (bodega,
     item,
     existencia,
     cuenta_inventarios,
     codigo_integracion)
    SELECT b.bodega,
           b.item,
           b.existencia,
           b.cuenta_inventarios,
           b.codigo_integracion
    FROM control_inventarios.bodegas b
             JOIN inventario_proceso.items i ON i.item = b.item
             JOIN control_inventarios.id_bodegas ib
                  ON b.bodega = ib.bodega AND (ib.planta_o_bodega = 'P' OR ib.planta_o_bodega = 'B') AND
                     ib.bodega <> '100' AND ib.bodega <> '999' AND
                     ib.bodega <> '008';

    INSERT INTO inventario_proceso.ubicaciones
    (bodega,
     ubicacion,
     item,
     existencia)
    SELECT u.bodega,
           u.ubicacion,
           u.item,
           u.existencia
    FROM control_inventarios.ubicaciones u
             JOIN inventario_proceso.items i ON i.item = u.item
             JOIN control_inventarios.id_bodegas ib
                  ON u.bodega = ib.bodega AND (ib.planta_o_bodega = 'P' OR ib.planta_o_bodega = 'B') AND
                     ib.bodega <> '100' AND ib.bodega <> '999' AND
                     ib.bodega <> '008';

    INSERT INTO inventario_proceso.costos
    (item,
     tipo_costo,
     mantenimiento_materia_prima_dolar,
     mantenimiento_materia_prima,
     mantenimiento_mano_obra,
     mantenimiento_gastos_fabricacion,
     nivel_materia_prima,
     nivel_mano_obra,
     nivel_gastos_fabricacion,
     acumulacion_materia_prima,
     acumulacion_mano_obra,
     acumulacion_gastos_fabricacion)
    SELECT c.item,
           c.tipo_costo,
           c.mantenimiento_materia_prima_dolar,
           c.mantenimiento_materia_prima,
           c.mantenimiento_mano_obra,
           c.mantenimiento_gastos_fabricacion,
           c.nivel_materia_prima,
           c.nivel_mano_obra,
           c.nivel_gastos_fabricacion,
           c.acumulacion_materia_prima,
           c.acumulacion_mano_obra,
           c.acumulacion_gastos_fabricacion
    FROM costos.costos c
             JOIN inventario_proceso.items i ON i.item = c.item;
END;
$function$
;
