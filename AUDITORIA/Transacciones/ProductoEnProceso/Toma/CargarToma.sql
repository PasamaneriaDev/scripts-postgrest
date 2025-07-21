CREATE OR REPLACE FUNCTION auditoria.ajuste_toma_produccion_consulta(p_documento varchar, p_computador varchar, p_usuario varchar)
    RETURNS table
            (
                item            varchar,
                descripcion     varchar,
                unidad_medida   varchar,
                costo           numeric,
                costo_nuevo     numeric,
                orden           varchar,
                cantidad        numeric,
                conos           numeric,
                tara            numeric,
                cajon           numeric,
                constante       numeric,
                muestra         varchar,
                cantidad_ajuste numeric,
                bodega          varchar,
                ubicacion       varchar,
                secuencia       integer,
                id_public       integer
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT aj.item,
               i.descripcion,
               i.unidad_medida,
               aj.costo,
               aj.costo_nuevo,
               aj.orden,
               aj.cantidad,
               aj.conos,
               aj.tara,
               aj.cajon,
               aj.constante,
               aj.muestra,
               aj.cantidad_ajuste,
               aj.bodega,
               aj.ubicacion,
               aj.secuencia,
               0 AS id_public
        FROM control_inventarios.ajustes aj
                 JOIN control_inventarios.items i ON i.item = aj.item
        WHERE aj.documento = p_documento
          AND aj.status <> 'V'
        UNION ALL
        SELECT aj.item,
               i.descripcion,
               i.unidad_medida,
               aj.costo,
               aj.costo_nuevo,
               aj.orden,
               aj.cantidad,
               aj.conos,
               aj.tara,
               aj.cajon,
               aj.constante,
               aj.muestra,
               aj.cantidad_ajuste,
               aj.bodega,
               aj.ubicacion,
               0 AS secuencia,
               aj.id_public
        FROM inventario_proceso.toma_producto_proceso_preliminar aj
                 JOIN control_inventarios.items i ON i.item = aj.item
        WHERE aj.documento = p_documento
          AND aj.computador = p_computador
          AND aj.usuario = p_usuario;
END;

$function$
;


select *
from control_inventarios.ajustes
where tipo = 'T'