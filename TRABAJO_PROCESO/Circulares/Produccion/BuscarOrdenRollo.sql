-- drop function if exists trabajo_proceso.orden_rollo_buscar_x_codigo_orden_codigo_barra(character varying);

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_buscar_x_codigo_orden_codigo_barra(string_buscar character varying)
    RETURNS TABLE
            (
                codigo_orden                 character varying,
                nro_rollo                    character varying,
                item                         character varying,
                cantidad_planificada         numeric,
                estado                       character varying,
                fecha_inicio_planificacion   date,
                fecha_entrega_real           date,
                fecha_emision                date,
                descripcion                  character varying,
                unidad_medida                character varying,
                maquina                      character varying,
                operario_registro_produccion character varying,
                peso_crudo                   numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    IF (SELECT * FROM "public".isdigit(string_buscar)) THEN
        RETURN QUERY
            SELECT o.codigo_orden,
                   od.numero_rollo,
                   o.item,
                   o.cantidad_planificada,
                   o.estado,
                   o.fecha_inicio_planificacion,
                   o.fecha_entrega_real,
                   o.fecha_emision,
                   i.descripcion,
                   i.unidad_medida,
                   o.maquina,
                   od.operario_registro_produccion,
                   od.peso_crudo
            FROM trabajo_proceso.ordenes o
                     JOIN trabajo_proceso.ordenes_rollos_detalle od ON o.codigo_orden = od.codigo_orden
                     INNER JOIN control_inventarios.items i ON o.item = i.item
            WHERE (o.secuencia_codigo_barra || od.numero_rollo) = CASE
                                                                      WHEN LENGTH(string_buscar) >= 12
                                                                          THEN LEFT(RIGHT(string_buscar, 12), 11)
                                                                      ELSE RIGHT('0000000000' || string_buscar, 11)
                END;
    ELSE
        RETURN QUERY
            SELECT o.codigo_orden,
                   od.numero_rollo,
                   o.item,
                   o.cantidad_planificada,
                   o.estado,
                   o.fecha_inicio_planificacion,
                   o.fecha_entrega_real,
                   o.fecha_emision,
                   i.descripcion,
                   i.unidad_medida,
                   o.maquina,
                   od.operario_registro_produccion,
                   od.peso_crudo
            FROM trabajo_proceso.ordenes o
                     JOIN trabajo_proceso.ordenes_rollos_detalle od ON o.codigo_orden = od.codigo_orden
                     INNER JOIN control_inventarios.items i ON o.item = i.item
            WHERE (o.codigo_orden || od.numero_rollo) = string_buscar;
    END IF;
END
$function$
;
