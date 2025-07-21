-- DROP FUNCTION trabajo_proceso.ordenes_mantenimiento(in bool, in varchar, in varchar, in bool, out varchar);

CREATE OR REPLACE FUNCTION trabajo_proceso.ordenes_mantenimiento(p_nuevo boolean, p_orden_data character varying,
                                                                 p_usuario character varying,
                                                                 p_item_coleccion_reapertura boolean,
                                                                 OUT error_msg character varying)
    RETURNS character varying
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _estado_lote                  VARCHAR;
    _es_item_coleccion            BOOLEAN = FALSE;
    _acceso_ordenes               BOOLEAN = TRUE;
    _cantidad_incremento          DECIMAL;
    _interface_activo             BOOLEAN;
    _codigo_orden                 trabajo_proceso.ordenes.codigo_orden%TYPE;
    _item                         trabajo_proceso.ordenes.item%TYPE;
    _cantidad_planificada         trabajo_proceso.ordenes.cantidad_planificada%TYPE;
    _fecha_emision                trabajo_proceso.ordenes.fecha_emision%TYPE;
    _fecha_inicio_planificacion   trabajo_proceso.ordenes.fecha_inicio_planificacion%TYPE;
    _fecha_entrega_planificada    trabajo_proceso.ordenes.fecha_entrega_planificada%TYPE;
    _prioridad                    trabajo_proceso.ordenes.prioridad%TYPE;
    _estado                       trabajo_proceso.ordenes.estado%TYPE;
    _comentario                   trabajo_proceso.ordenes.comentario%TYPE;
    _comentario_spp               trabajo_proceso.ordenes.comentario%TYPE; --2019-06-28 mp para evitar enter en campo comentario
    _problema                     trabajo_proceso.ordenes.problema%TYPE;
    _estado_original              trabajo_proceso.ordenes.estado%TYPE;
    _cantidad_planificada_orginal trabajo_proceso.ordenes.cantidad_fabricada%TYPE;
    _manual                       trabajo_proceso.ordenes.manual%TYPE;
    _neto                         trabajo_proceso.ordenes.cantidad_fabricada%TYPE;
    _cantidad_fabricada_actual    trabajo_proceso.ordenes.cantidad_fabricada%TYPE;
    _codigo_coleccion             trabajo_proceso.ordenes.codigo_coleccion%TYPE;
    _ultimo_lote_malla            trabajo_proceso.ordenes.ultimo_lote_malla%TYPE;
    _secuencia_programa           trabajo_proceso.ordenes.secuencia_programa%TYPE;
    _maquina                      trabajo_proceso.ordenes.maquina%TYPE;
    _codigo_orden_padre           trabajo_proceso.ordenes_reproceso.codigo_orden_reproceso%TYPE;
    _modificador_op_tipo_id       SMALLINT;

BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    error_msg = '';

    SELECT codigo_orden
         , TRIM(item)
         , cantidad_planificada
         , fecha_emision
         , fecha_inicio_planificacion
         , fecha_entrega_planificada
         , prioridad
         , estado
         , comentario
         , problema
         , estado_original
         , cantidad_planificada_orginal
         , COALESCE(manual, FALSE)            AS manual
         , modificador_op_tipo_id
         , codigo_coleccion
         , COALESCE(ultimo_lote_malla, FALSE) AS ultimo_lote_malla
         , COALESCE(secuencia_programa, 0)    AS secuencia_programa
         , COALESCE(maquina, '')              AS maquina
         , COALESCE(codigo_orden_padre, '')   AS codigo_orden_padre
    INTO
        _codigo_orden, _item, _cantidad_planificada, _fecha_emision, _fecha_inicio_planificacion
        , _fecha_entrega_planificada, _prioridad, _estado, _comentario, _problema
        , _estado_original, _cantidad_planificada_orginal, _manual, _modificador_op_tipo_id,_codigo_coleccion
        , _ultimo_lote_malla, _secuencia_programa, _maquina, _codigo_orden_padre
    FROM JSON_POPULATE_RECORD(NULL::trabajo_proceso.ordenes_type, p_orden_data::JSON);

    _cantidad_incremento = _cantidad_planificada - _cantidad_planificada_orginal;

    --2019-06-28 mp para evitar enter en campo comentario
    IF COALESCE(_comentario, '') = '' THEN
        _comentario_spp = '[]';

    ELSE
        SELECT x.comenario_1
        INTO _comentario_spp --2019-06-28 mp reemplaza enter por chr(13)
        FROM rutas.ruta_narrativa_prepara_interface_vfp_fnc(_comentario) x (comenario_1);

        _comentario_spp = COALESCE(_comentario_spp, '[]');

    END IF;
    --2019-06-28

    IF p_nuevo THEN

        INSERT INTO trabajo_proceso.ordenes
        ( codigo_orden, item, secuencia_codigo_barra, cantidad_planificada, fecha_emision
        , fecha_inicio_planificacion, fecha_entrega_planificada, prioridad, estado, comentario
        , problema, manual, tiene_requerimientos, tiene_hoja_ruta, codigo_coleccion, ultimo_lote_malla
        , secuencia_programa, maquina)
        VALUES ( _codigo_orden, _item, '', _cantidad_planificada, _fecha_emision
               , _fecha_inicio_planificacion, _fecha_entrega_planificada, _prioridad, _estado, _comentario
               , _problema, _manual, FALSE, FALSE, _codigo_coleccion, _ultimo_lote_malla, _secuencia_programa
               , _maquina);

        IF (SELECT p_interface_activo FROM sistema.interface_activo_fnc()) = TRUE THEN
            INSERT INTO sistema.interface
                (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
            SELECT '$DESTAJO'
                 , 'INSERT1'
                 , 'ordenes'
                 , ''
                 , 'f:\home\spp\trabproc\data\ '
                 , ''
                 , 'INSERT INTO f:\home\spp\trabproc\data\ordenes (' ||
                   '  item, codorden, seccodbar, cantplanif, fecentplan, fecemision, ' ||
                   '  feciniplan, prioridad, estado, comentario, problemas, manual, ' ||
                   '  bandrequer, bandhojaru, codcolecci, ultlotmall, secuprogra, maquina)' ||
                   ' VALUES (' ||
                   '[' || _item || '], [' || _codigo_orden || '], [], ' ||
                   COALESCE(_cantidad_planificada, 0)::VARCHAR ||
                   ', ' ||
                   CASE
                       WHEN _fecha_entrega_planificada IS NULL THEN '{//}, '
                       ELSE '{^' || TO_CHAR(_fecha_entrega_planificada, 'YYYY-MM-DD') || '}, ' END ||
                   CASE
                       WHEN _fecha_emision IS NULL THEN '{//}, '
                       ELSE '{^' || TO_CHAR(_fecha_emision, 'YYYY-MM-DD') || '}, ' END ||
                   CASE
                       WHEN _fecha_inicio_planificacion IS NULL THEN '{//}, '
                       ELSE '{^' || TO_CHAR(_fecha_inicio_planificacion, 'YYYY-MM-DD') || '}, ' END ||
                   '[' || COALESCE(_prioridad, '') || '], [' || COALESCE(_estado, '') || '], ' || _comentario_spp ||
                   ', [' || COALESCE(_problema, '') || '], ' ||
                   CASE WHEN _manual THEN '.T.' ELSE '.F.' END || ', .F., .F., [' || COALESCE(_codigo_coleccion, '') ||
                   '],' ||
                   CASE WHEN _ultimo_lote_malla THEN '.T.' ELSE '.F.' END || ',' ||
                   COALESCE(_secuencia_programa, 0)::VARCHAR ||
                   ',[' || COALESCE(_maquina, '') || '])';
            --2019-06-28 '[' || COALESCE(_prioridad, '') || '], [' || COALESCE(_estado, '') || '], [' || COALESCE(_comentario, '') || '], [' || COALESCE(_problema, '') || '], ' ||

        END IF;

        PERFORM *
        FROM trabajo_proceso.ordenes_produccion_creacion
             (_codigo_orden, _item, _cantidad_planificada, FALSE, _manual, p_usuario);

        -- ordenes_produccion_creacion(p_codigo_orden, p_item, p_cantidad, p_ordenes_devolucion, p_manual, p_usuario, p_requerimiento_genera DEFAULT false, p_requerimiento_data)
        -- Los 2 ultimos paramentros son necesario si se ejecuta desde el mantenimiento de ordenes de prodcucción

        --240828 mp inserta en tabla trabajo_proceso.ordenes_reproceso para dar trazabilidad a las ordenes generadas
        -- por reproceso o reproceso por cambio de coloer
        IF _codigo_orden_padre <> '' THEN
            INSERT INTO trabajo_proceso.ordenes_reproceso
                (codigo_orden, codigo_orden_reproceso)
            VALUES (_codigo_orden_padre, _codigo_orden);

        END IF;
        --240828 mp

    ELSE --edicion

        SELECT l.estado
        INTO _estado_lote
        FROM colecciones.lotes_detalle l
        WHERE l.item = _item;

        IF _estado_lote IS DISTINCT FROM NULL THEN
            _es_item_coleccion = TRUE;

            SELECT a.acceso_especial
            INTO _acceso_ordenes
            FROM sistema.accesos a
            WHERE a.codigo = p_usuario
              AND a.proceso = 'mantenimientoOrdenesdeTrabajo';

            IF _acceso_ordenes IS NULL THEN
                _acceso_ordenes = FALSE;

            END IF;
        END IF;

        IF _estado_original = 'Abierta' AND _estado = 'Cerrada' THEN
            IF _es_item_coleccion AND _acceso_ordenes = FALSE THEN
                error_msg = 'No tiene acceso a cerrar ordenes que pertenecen a items de colección.';
                RETURN;

            ELSE
                SELECT o.cantidad_fabricada
                INTO _cantidad_fabricada_actual
                FROM trabajo_proceso.ordenes o
                WHERE o.codigo_orden = _codigo_orden;

                _neto = _cantidad_planificada_orginal - _cantidad_fabricada_actual;

                IF _neto < 0 THEN
                    _neto = 0;

                END IF;

                --cierre de orden
                PERFORM *
                FROM trabajo_proceso.cierre_ordenes_produccion(_codigo_orden, _item, _neto, p_usuario);


            END IF;
        ELSE
            IF _estado_original = 'Cerrada' AND _estado = 'Abierta' THEN
                IF _es_item_coleccion AND _acceso_ordenes = FALSE THEN
                    error_msg =
                            'No tiene acceso para reaperturar ordenes que pertenecen a items de colección y fueron cerradas.';
                    RETURN;

                ELSE
                    SELECT o.cantidad_fabricada
                    INTO _cantidad_fabricada_actual
                    FROM trabajo_proceso.ordenes o
                    WHERE o.codigo_orden = _codigo_orden;

                    _neto = _cantidad_planificada_orginal - _cantidad_fabricada_actual;

                    IF _neto < 0 THEN
                        _neto = 0;

                    END IF;

                    IF _es_item_coleccion AND p_item_coleccion_reapertura THEN --Si es item de coleccion y usario pide reapertura de orden
                        PERFORM *
                        FROM trabajo_proceso.reapertura_ordenes_produccion(_codigo_orden, _item, _neto,
                                                                           _cantidad_planificada, p_usuario);
                    ELSE
                        PERFORM *
                        FROM trabajo_proceso.reapertura_ordenes_produccion(_codigo_orden, _item, _neto,
                                                                           _cantidad_planificada, p_usuario);
                    END IF;

                END IF;
                /*else -- mp 240419 se cambia de lugar, en ocaciones el usuario activa una orden y cambia la cantidad esta no se registra por los condicionales que le preceden
                    if _cantidad_planificada_orginal <> _cantidad_planificada THEN
                        if _estado = 'Abierta' THEN
                            if _es_item_coleccion And _acceso_ordenes = FALSE THEN
                                error_msg = 'No tiene acceso a modificar ordenes que pertenecen a items de colección.';
                                RETURN;

                            ELSE
                                Perform *
                                 From trabajo_proceso.orden_produccion_modifica(_codigo_orden, _cantidad_planificada, _item, _cantidad_incremento, p_usuario);

                            end if;
                        else
                            error_msg = 'No se puede modificar, orden cerrada.';
                            RETURN;

                        end if;
                    end if;*/
            END IF;


            -- mp 240419 se cambia de lugar, en ocaciones el usuario activa una orden y cambia la cantidad esta no se registra por los condicionales que le preceden
            IF _cantidad_planificada_orginal <> _cantidad_planificada THEN
                IF _estado = 'Abierta' THEN
                    IF _es_item_coleccion AND _acceso_ordenes = FALSE THEN
                        error_msg = 'No tiene acceso a modificar ordenes que pertenecen a items de colección.';
                        RETURN;

                    ELSE
                        PERFORM *
                        FROM trabajo_proceso.orden_produccion_modifica(_codigo_orden, _cantidad_planificada, _item,
                                                                       _cantidad_incremento, p_usuario);

                    END IF;
                ELSE
                    error_msg = 'No se puede modificar, orden cerrada.';
                    RETURN;

                END IF;
            END IF;
            --

            --mp 2023-05-24 registra causa de modificación de cantidad
            IF _modificador_op_tipo_id > 0 THEN
                INSERT INTO trabajo_proceso.ordenes_produccion_modificadas
                (codigo_orden, modificador_op_tipo_id, cantidad_original, cantidad_nueva, usuario_id)
                VALUES (_codigo_orden, _modificador_op_tipo_id, _cantidad_planificada_orginal, _cantidad_planificada,
                        p_usuario);

            END IF;
            --mp 2023-05-24

        END IF;


        WITH t
                 AS
                 (
                     UPDATE trabajo_proceso.ordenes o
                         SET fecha_inicio_planificacion = CASE
                                                              WHEN o.fecha_inicio_planificacion = _fecha_inicio_planificacion
                                                                  THEN o.fecha_inicio_planificacion
                                                              ELSE _fecha_inicio_planificacion END
                             , fecha_entrega_planificada = CASE
                                                               WHEN o.fecha_entrega_planificada = _fecha_entrega_planificada
                                                                   THEN o.fecha_entrega_planificada
                                                               ELSE _fecha_entrega_planificada END
                             , cantidad_planificada = CASE
                                                          WHEN o.cantidad_planificada = _cantidad_planificada
                                                              THEN o.cantidad_planificada
                                                          ELSE _cantidad_planificada END
                             , prioridad = CASE WHEN o.prioridad = _prioridad THEN o.prioridad ELSE _prioridad END
                             , estado = CASE WHEN o.estado = _estado THEN o.estado ELSE _estado END
                             , comentario = CASE WHEN o.comentario = _comentario THEN o.comentario ELSE _comentario END
                             , problema = CASE WHEN o.problema = _problema THEN o.problema ELSE _problema END
                         WHERE o.codigo_orden = _codigo_orden
                         RETURNING o.codigo_orden, o.fecha_inicio_planificacion, o.fecha_entrega_planificada, o.cantidad_planificada, o.prioridad, o.estado
                             , COALESCE(o.comentario, '') AS comentario, COALESCE(o.problema, '') AS problema)
        INSERT
        INTO sistema.interface
            (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
        SELECT 'TRABAJO EN PROCESO'
             , 'UPDATE1'
             , 'ordenes'
             , ''
             , 'f:\home\spp\trabproc\data\ '
             , '' /* MP 2019-08-19 09:22  Cambio por destiempo de actualizacion de reapertura de ordenes (a partir de un egreso) antes $DESTAJO*/
             , 'UPDATE f:\home\spp\trabproc\data\ordenes ' ||
               'Set feciniplan = {^' || TO_CHAR(t.fecha_inicio_planificacion, 'YYYY-MM-DD') || '} ' ||
               ', fecentplan = {^' || TO_CHAR(t.fecha_entrega_planificada, 'YYYY-MM-DD') || '} ' ||
               ', cantplanif = ' || t.cantidad_planificada::VARCHAR ||
               ', prioridad  = [' || t.prioridad || '] ' ||
               ', estado			= [' || t.estado || '] ' ||
               ', comentario = ' || _comentario_spp ||
               ', problemas  = [' || t.problema || '] ' ||
               'Where	codorden = [' || RPAD(t.codigo_orden, 15, ' ') || ']'
        FROM t
        WHERE _interface_activo;
        --2019-06-28 ', comentario = ['	|| t.comentario || '] ' ||
    END IF;

END;
$function$
;
