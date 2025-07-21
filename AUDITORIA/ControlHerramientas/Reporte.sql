 -- DROP FUNCTION auditoria.reporte_entrega_herramientas(varchar, bool);

CREATE OR REPLACE FUNCTION auditoria.reporte_entrega_herramientas(p_documento character varying, p_reverso boolean)
    RETURNS TABLE
            (
                codigo_documento            character varying,
                descripcion                 character varying,
                nombre_usuario_revisa       character varying,
                fecha_entrega               date,
                fecha_ultima_revision       date,
                total_herramienta           integer,
                codigo_responsable1         character varying,
                nombre_responsable1         character varying,
                seccion1                    character varying,
                codigo_responsable2         character varying,
                nombre_responsable2         character varying,
                seccion2                    character varying,
                codigo_responsable3         character varying,
                nombre_responsable3         character varying,
                seccion3                    character varying,
                codigo_responsable4         character varying,
                nombre_responsable4         character varying,
                seccion4                    character varying,
                codigo_responsable5         character varying,
                nombre_responsable5         character varying,
                seccion5                    character varying,
                codigo_responsable6         character varying,
                nombre_responsable6         character varying,
                seccion6                    character varying,
                nombre_responsable_anterior character varying,
                seccion_anterior            character varying,
                item                        character varying,
                descripcion_item            character varying,
                marca                       character varying,
                cantidad_entregada          integer,
                observacion                 character varying,
                reverso                     text
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    RETURN QUERY
        SELECT ch.codigo_documento,
               ch.descripcion,
               ch.nombre_usuario_revisa,
               ch.fecha_entrega,
               ch.fecha_ultima_revision,
               ch.total_herramienta,
               ch.codigo_responsable1,
               ch.nombre_responsable1,
               ch.seccion1,
               ch.codigo_responsable2,
               ch.nombre_responsable2,
               ch.seccion2,
               ch.codigo_responsable3,
               ch.nombre_responsable3,
               ch.seccion3,
               ch.codigo_responsable4,
               ch.nombre_responsable4,
               ch.seccion4,
               ch.codigo_responsable5,
               ch.nombre_responsable5,
               ch.seccion5,
               ch.codigo_responsable6,
               ch.nombre_responsable6,
               ch.seccion6,
               ch.nombre_responsable_anterior,
               ch.seccion_anterior,
               dh.item,
               dh.descripcion AS descripcion_item,
               dh.marca,
               dh.cantidad_entregada,
               dh.observacion,
               CASE
                   WHEN p_reverso THEN
                       'REVERSO'
                   ELSE
                       ''
                   END        AS reverso
        FROM auditoria.cabecera_inventario_herramienta ch
                 JOIN auditoria.detalle_inventario_herramienta_order_view dh
                      ON ch.codigo_documento = dh.codigo_documento
        WHERE ch.codigo_documento = p_documento
          AND dh.eliminado = FALSE;
END;
$function$
;
