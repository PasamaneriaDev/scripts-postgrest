-- DROP FUNCTION auditoria.inventario_herramienta_grabar_fnc(p_codigo_documento varchar, p_datajs character varying)

CREATE OR REPLACE FUNCTION auditoria.inventario_herramienta_grabar_fnc(p_codigo_documento varchar,
                                                                       p_datajs character varying,
                                                                       OUT v_codigo_documento varchar)
    RETURNS varchar
    LANGUAGE plpgsql
AS
$function$

BEGIN

    IF COALESCE(p_codigo_documento, '') = '' THEN
        UPDATE sistema.parametros
        SET numero = numero + 1
        WHERE modulo_id = 'AUDITORIA'
          AND codigo = 'NUM_LISTADO_HE'
        RETURNING numero::int INTO v_codigo_documento;
        v_codigo_documento := 'LIS-' || TO_CHAR(v_codigo_documento::int, 'FM000');
        -- INSERTAMOS EL REGISTRO DE CABECERA
        INSERT INTO auditoria.cabecera_inventario_herramienta (codigo_documento, descripcion, codigo_responsable1,
                                                               codigo_responsable2, codigo_responsable3,
                                                               codigo_responsable4, codigo_responsable5,
                                                               codigo_responsable6, nombre_responsable1,
                                                               nombre_responsable2, nombre_responsable3,
                                                               nombre_responsable4, nombre_responsable5,
                                                               nombre_responsable6, nombre_responsable_anterior,
                                                               codigo_seccion1, seccion1, codigo_seccion2, seccion2,
                                                               codigo_seccion3, seccion3, codigo_seccion4, seccion4,
                                                               codigo_seccion5, seccion5, codigo_seccion6, seccion6,
                                                               seccion_anterior, codigo_usuario_revisa,
                                                               nombre_usuario_revisa, fecha_ultima_revision,
                                                               fecha_entrega, total_herramienta, estado)
        SELECT v_codigo_documento,
               x.descripcion,
               x.codigo_responsable1,
               x.codigo_responsable2,
               x.codigo_responsable3,
               x.codigo_responsable4,
               x.codigo_responsable5,
               x.codigo_responsable6,
               x.nombre_responsable1,
               x.nombre_responsable2,
               x.nombre_responsable3,
               x.nombre_responsable4,
               x.nombre_responsable5,
               x.nombre_responsable6,
               x.nombre_responsable_anterior,
               x.codigo_seccion1,
               x.seccion1,
               x.codigo_seccion2,
               x.seccion2,
               x.codigo_seccion3,
               x.seccion3,
               x.codigo_seccion4,
               x.seccion4,
               x.codigo_seccion5,
               x.seccion5,
               x.codigo_seccion6,
               x.seccion6,
               x.seccion_anterior,
               x.codigo_usuario_revisa,
               x.nombre_usuario_revisa,
               x.fecha_ultima_revision::date,
               x.fecha_entrega::date,
               x.total_herramienta,
               x.estado
        FROM JSONB_TO_RECORD(p_datajs::jsonb) x (descripcion TEXT,
                                                 codigo_responsable1 TEXT, codigo_responsable2 TEXT,
                                                 codigo_responsable3 TEXT, codigo_responsable4 TEXT,
                                                 codigo_responsable5 TEXT, codigo_responsable6 TEXT,
                                                 nombre_responsable1 TEXT, nombre_responsable2 TEXT,
                                                 nombre_responsable3 TEXT, nombre_responsable4 TEXT,
                                                 nombre_responsable5 TEXT, nombre_responsable6 TEXT,
                                                 nombre_responsable_anterior TEXT, codigo_seccion1 TEXT,
                                                 seccion1 TEXT, codigo_seccion2 TEXT, seccion2 TEXT,
                                                 codigo_seccion3 TEXT, seccion3 TEXT, codigo_seccion4 TEXT,
                                                 seccion4 TEXT, codigo_seccion5 TEXT, seccion5 TEXT,
                                                 codigo_seccion6 TEXT, seccion6 TEXT, seccion_anterior TEXT,
                                                 codigo_usuario_revisa TEXT, nombre_usuario_revisa TEXT,
                                                 fecha_ultima_revision TEXT, fecha_entrega TEXT,
                                                 total_herramienta integer, estado TEXT);

        -- INSERTAMOS LOS DETALLES
        INSERT INTO auditoria.detalle_inventario_herramienta (codigo_documento, item, descripcion, marca,
                                                              cantidad_entregada, observacion,
                                                              fecha_entrega)
        SELECT v_codigo_documento,
               item,
               descripcion,
               marca,
               cantidad_entregada,
               observacion,
               CURRENT_DATE
        FROM JSONB_TO_RECORDSET((p_datajs::jsonb ->> 'detalles')::jsonb) x (item text, descripcion TEXT, marca TEXT,
                                                                            cantidad_entregada integer,
                                                                            observacion TEXT);

    ELSE
        v_codigo_documento := p_codigo_documento;

        -- ACTUALIZAMOS EL REGISTRO DE CABECERA
        UPDATE auditoria.cabecera_inventario_herramienta
        SET descripcion                 = x.descripcion,
            codigo_responsable1         = x.codigo_responsable1,
            codigo_responsable2         = x.codigo_responsable2,
            codigo_responsable3         = x.codigo_responsable3,
            codigo_responsable4         = x.codigo_responsable4,
            codigo_responsable5         = x.codigo_responsable5,
            codigo_responsable6         = x.codigo_responsable6,
            nombre_responsable1         = x.nombre_responsable1,
            nombre_responsable2         = x.nombre_responsable2,
            nombre_responsable3         = x.nombre_responsable3,
            nombre_responsable4         = x.nombre_responsable4,
            nombre_responsable5         = x.nombre_responsable5,
            nombre_responsable6         = x.nombre_responsable6,
            nombre_responsable_anterior = x.nombre_responsable_anterior,
            codigo_seccion1             = x.codigo_seccion1,
            seccion1                    = x.seccion1,
            codigo_seccion2             = x.codigo_seccion2,
            seccion2                    = x.seccion2,
            codigo_seccion3             = x.codigo_seccion3,
            seccion3                    = x.seccion3,
            codigo_seccion4             = x.codigo_seccion4,
            seccion4                    = x.seccion4,
            codigo_seccion5             = x.codigo_seccion5,
            seccion5                    = x.seccion5,
            codigo_seccion6             = x.codigo_seccion6,
            seccion6                    = x.seccion6,
            seccion_anterior            = x.seccion_anterior,
            codigo_usuario_revisa       = x.codigo_usuario_revisa,
            nombre_usuario_revisa       = x.nombre_usuario_revisa,
            fecha_ultima_revision       = x.fecha_ultima_revision::date,
            fecha_entrega               = x.fecha_entrega::date,
            total_herramienta           = x.total_herramienta,
            estado                      = x.estado
        FROM JSONB_TO_RECORD(p_datajs::jsonb) x (descripcion TEXT,
                                                 codigo_responsable1 TEXT, codigo_responsable2 TEXT,
                                                 codigo_responsable3 TEXT, codigo_responsable4 TEXT,
                                                 codigo_responsable5 TEXT, codigo_responsable6 TEXT,
                                                 nombre_responsable1 TEXT, nombre_responsable2 TEXT,
                                                 nombre_responsable3 TEXT, nombre_responsable4 TEXT,
                                                 nombre_responsable5 TEXT, nombre_responsable6 TEXT,
                                                 nombre_responsable_anterior TEXT, codigo_seccion1 TEXT,
                                                 seccion1 TEXT, codigo_seccion2 TEXT, seccion2 TEXT,
                                                 codigo_seccion3 TEXT, seccion3 TEXT, codigo_seccion4 TEXT,
                                                 seccion4 TEXT, codigo_seccion5 TEXT, seccion5 TEXT,
                                                 codigo_seccion6 TEXT, seccion6 TEXT, seccion_anterior TEXT,
                                                 codigo_usuario_revisa TEXT, nombre_usuario_revisa TEXT,
                                                 fecha_ultima_revision TEXT, fecha_entrega TEXT,
                                                 fecha_devolucion TEXT, total_herramienta integer, estado TEXT)
        WHERE codigo_documento = v_codigo_documento;

        -- ELIMINAMOS LOS DETALLES
        -- DELETE
        -- FROM auditoria.detalle_inventario_herramienta
        -- WHERE codigo_documento = v_codigo_documento;

        -- INSERTAMOS LOS DETALLES
        -- INSERT INTO auditoria.detalle_inventario_herramienta (codigo_documento, item, descripcion, marca,
        --                                                       cantidad_entregada, observacion,
        --                                                       fecha_entrega)
        -- SELECT v_codigo_documento,
        --        item,
        --        descripcion,
        --        marca,
        --        cantidad_entregada,
        --        observacion,
        --        CASE WHEN COALESCE(fecha_entrega, '') = '' THEN CURRENT_DATE ELSE fecha_entrega::date END
        -- FROM JSONB_TO_RECORDSET((p_datajs::jsonb ->> 'detalles')::jsonb) x (item text, descripcion TEXT, marca TEXT,
        --                                                            cantidad_entregada integer, observacion TEXT,
        --                                                            fecha_entrega TEXT);

        -- ACTUALIZAMOS LOS DETALLES EXISTENTES
        UPDATE auditoria.detalle_inventario_herramienta
        SET eliminado = TRUE
        WHERE codigo_documento = v_codigo_documento
          AND secuencia NOT IN (SELECT secuencia
                                FROM JSONB_TO_RECORDSET((p_datajs::jsonb ->> 'detalles')::jsonb) x (secuencia integer));

        -- INSERTAMOS O ACTUALIZAMOS LOS DETALLES
        INSERT INTO auditoria.detalle_inventario_herramienta (codigo_documento, item, descripcion, marca,
                                                              cantidad_entregada, observacion, fecha_entrega)
        SELECT v_codigo_documento,
               x.item,
               x.descripcion,
               x.marca,
               x.cantidad_entregada,
               x.observacion,
               current_date
        FROM JSONB_TO_RECORDSET((p_datajs::jsonb ->> 'detalles')::jsonb) x (secuencia integer, item varchar,
                                                                            descripcion TEXT,
                                                                            marca TEXT,
                                                                            cantidad_entregada integer,
                                                                            observacion TEXT,
                                                                            fecha_entrega TEXT)
        WHERE x.secuencia = -1;

        -- ACTUALIZAMOS LOS DETALLES EXISTENTES
        UPDATE auditoria.detalle_inventario_herramienta ih
        SET descripcion        = x.descripcion,
            marca              = x.marca,
            cantidad_entregada = x.cantidad_entregada,
            observacion        = x.observacion,
            eliminado          = FALSE
        FROM JSONB_TO_RECORDSET((p_datajs::jsonb ->> 'detalles')::jsonb) x (secuencia integer, descripcion TEXT,
                                                                            marca TEXT,
                                                                            cantidad_entregada integer,
                                                                            observacion TEXT,
                                                                            fecha_entrega TEXT)
        WHERE x.secuencia IS NOT NULL
        and x.secuencia = ih.secuencia;

    END IF;


END ;
$function$
;

