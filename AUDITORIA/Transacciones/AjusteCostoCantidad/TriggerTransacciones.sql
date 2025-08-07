-- DROP FUNCTION control_inventarios.valida_graba_transacciones_ok();

CREATE OR REPLACE FUNCTION control_inventarios.valida_graba_transacciones_ok()
    RETURNS trigger
    LANGUAGE plpgsql
AS
$function$
DECLARE

    wSecuencia               integer;
    wItem                    character(15);
    wExistencia              numeric(10, 3);
    wCostoPromedio           numeric(15, 5);
    wcosto_estandar          numeric(15, 5);
    wBodegaConTransito       boolean; --bandera usada para saber si es una bodega que tiene transito
    wExisteUbicacion         integer; --bandera usada para saber si existe la ubicacion en el archivo de id_ubicaciones
    wCantidadRecibida        numeric(10, 3);
    wSqlGrabaInterface       character varying; --bandera usada para grabar en la tabla interface
    wFechaGrabaVisual        character varying; --bandera usada para grabar en la tabla interface
    wEs_Stock                boolean; --bandera usada para saber si se tiene que actualizar el inventario.
    wctainv                  character varying; --bandera usada para grabar las ctas contables en el iciloc01
    wctacomp                 character varying; --bandera usada para grabar las ctas contables en el iciloc01
    wctaajus                 character varying; --bandera usada para grabar las ctas contables en el iciloc01
    wctainteg                character varying; --bandera usada para grabar las ctas contables en el iciloc01
    wperiodo                 character(6); --bandera usada para grabar las ctas contables en el iciloc01
    wCostoUnitTotal          numeric(15, 5); --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wCTV                     numeric(15, 5); --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wEs_Vendible             boolean; --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wPrimRecepcion999        DATE; --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wUltimoIngreso           date; --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wOrdenesTrabajo          numeric(10, 3); --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wUltimaRecepcion         date; --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wCantidadPosibleARestar  numeric(10, 3); --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wFechaEntregaReal        date; --bandera usada en ingresos/devoluciones de planta  2017/04/18
    wComentario              character varying;
    Lv_Extprice              numeric(10, 2);
    Ld_primera_venta         date;
    Lb_CreaUbicacion         BOOLEAN := FALSE; --LWO 2019-07-23. Variable utilizada para evitar desfaces en la interface.
    _es_fabricado            control_inventarios.items.es_fabricado%type;
    _costo_estandar          control_inventarios.items.costo_estandar%Type;
    Ld_Primera_Recepcion_999 DATE;

BEGIN

    --LWO 2014/09/24. Estas lineas fueron agregadas para poder eliminar transacciones que todavia no han sido actualizadas (status='U').
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    -------------------------

    IF TG_OP = 'INSERT' THEN
        IF UPPER(NEW.migracion) = 'SI' THEN
            RETURN NEW;
        END IF;
    END IF;

    -- LWO 2015/01/28
    -- A partir de esta fecha, se graba el periodo.
    IF TG_OP = 'INSERT' THEN
        SELECT TO_CHAR(NEW.Fecha, 'YYYYMM') INTO wPeriodo;
        NEW.periodo = wPeriodo;
    END IF;
    -------------------------

    --LWO 2014/09/30. Si no es un item de stock, no se tiene que actualizar el inventario en ningún archivo que maneja inventarios.
    SELECT es_stock
    INTO wEs_Stock
    FROM control_inventarios.items
    WHERE item = NEW.item
      AND es_comprado = TRUE
      AND es_fabricado = FALSE;

    IF wEs_Stock = FALSE THEN
        RETURN NEW;
    END IF;
    --------------------------

    DROP TABLE IF EXISTS es_vfp;


    --IF NEW.tipo_movimiento = 'COMP EXT' THEN
    -- NEW.es_psql := TRUE;
    --END IF;

    /*si es que viene de interfas es_psql = FALSE*/
    IF NEW.es_psql = FALSE THEN
        CREATE TEMPORARY TABLE es_vfp
        (
            vfp BOOLEAN
        );
    END IF;

    IF TG_OP = 'INSERT' AND NOT NEW.tipo_movimiento IN ('REUB CANT-', 'REUB CANT+', 'TRANSFER-',
                                                        'TRANSFER+') THEN --Reubicaciones y transferencias se procesan mas abajo,


    -- Actualiza el archivos de inventario
        CASE NEW.tipo_movimiento
            -- VENTAS Y DEVOLUCIONES EN ALMACENES Y COMISARIATO
            WHEN 'VTAS ALM','DEVO ALM','VTAS MAY','DEVO MAY' THEN IF NOT EXISTS(SELECT item
                                                                                FROM control_inventarios.bodegas
                                                                                WHERE bodega = NEW.bodega
                                                                                  AND item = NEW.item) THEN
                INSERT INTO control_inventarios.bodegas (bodega, item, creacion_usuario)
                VALUES (NEW.bodega, NEW.item, NEW.creacion_usuario);
                                                                  END IF;

                                                                  Lv_Extprice = (NEW.cantidad * NEW.precio) -
                                                                                (NEW.cantidad * NEW.precio) *
                                                                                (NEW.descuento / 100);

            -- Existencia por Bodegas
                                                                  UPDATE control_inventarios.bodegas
                                                                  SET existencia               = existencia + NEW.cantidad,
                                                                      ultima_venta             = NOW(),
                                                                      cantidad_vendida_periodo = cantidad_vendida_periodo + (NEW.cantidad * -1),
                                                                      valor_vendido_periodo    = valor_vendido_periodo + (Lv_Extprice * -1),
                                                                      cantidad_vendida_ano     = cantidad_vendida_ano + (NEW.cantidad * -1),
                                                                      valor_vendido_ano        = valor_vendido_ano + (Lv_Extprice * -1)
                                                                  WHERE bodega = NEW.bodega
                                                                    AND item = NEW.item;

            --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                                                  IF New.es_psql THEN
                                                                      wSqlGrabaInterface =
                                                                              'REPLACE lonhand WITH lonhand+' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                              ','
                                                                                  || 'lsale WITH {^' ||
                                                                              TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '},'
                                                                                  || 'ptdslqt WITH ptdslqt+' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad * -1, '9999999.999')) ||
                                                                              ','
                                                                                  || 'ptdslvl WITH ptdslvl+' ||
                                                                              TRIM(TO_CHAR(Lv_Extprice * -1, '9999999999.99999')) ||
                                                                              ','
                                                                                  || 'ytdslqt WITH ytdslqt+' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad * -1, '9999999.999')) ||
                                                                              ','
                                                                                  || 'ytdslvl WITH ytdslvl+' ||
                                                                              TRIM(TO_CHAR(Lv_Extprice * -1, '9999999999.99999'));

                                                                      INSERT INTO sistema.interface (fecha, hora,
                                                                                                     usuarios,
                                                                                                     generador, modulo,
                                                                                                     actualizad, sql,
                                                                                                     proceso,
                                                                                                     directorio, tabla,
                                                                                                     buscar, codigo)
                                                                      VALUES (NEW.creacion_fecha, NEW.creacion_hora,
                                                                              NEW.creacion_usuario, 'LINUX',
                                                                              '$PTOVENTA', 'NO', wSqlGrabaInterface,
                                                                              'UPDATE', 'v:\sbtpro\icdata\ ',
                                                                              'iciloc01',
                                                                              '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                              RPAD(NEW.bodega, 3, ' ') ||
                                                                              '","Iciloc01","Item1"' || ')', NEW.item);
                                                                  END IF;
            ----------------------------------------


                                                                  IF NOT EXISTS(SELECT item
                                                                                FROM control_inventarios.ubicaciones
                                                                                WHERE bodega = NEW.bodega
                                                                                  AND item = NEW.item
                                                                                  AND ubicacion = NEW.ubicacion) THEN
                                                                      INSERT INTO control_inventarios.ubicaciones (bodega, item, ubicacion, creacion_usuario)
                                                                      VALUES (NEW.bodega, NEW.item, NEW.ubicacion,
                                                                              NEW.creacion_usuario);
                                                                      Lb_CreaUbicacion = TRUE;
                                                                  END IF;

            -- Existencia por Ubicaciones
                                                                  UPDATE control_inventarios.ubicaciones
                                                                  SET existencia    = existencia + NEW.cantidad,
                                                                      ultimo_egreso = NOW()
                                                                  WHERE bodega = NEW.bodega
                                                                    AND item = NEW.item
                                                                    AND ubicacion = NEW.ubicacion;

            --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                                                  IF New.es_psql THEN
                                                                      wSqlGrabaInterface =
                                                                              'REPLACE qonhand WITH qonhand +' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                              ','
                                                                                  || 'issued WITH {^' ||
                                                                              TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';

                                                                      INSERT INTO sistema.interface (fecha, hora,
                                                                                                     usuarios,
                                                                                                     generador, modulo,
                                                                                                     actualizad, sql,
                                                                                                     proceso,
                                                                                                     directorio, tabla,
                                                                                                     buscar, codigo)
                                                                      VALUES (NEW.creacion_fecha, NEW.creacion_hora,
                                                                              NEW.creacion_usuario, 'LINUX', CASE
                                                                                                                 WHEN Lb_CreaUbicacion = TRUE
                                                                                                                     THEN 'LISTA_MATERIALES'
                                                                                                                 ELSE '$PTOVENTA' END,
                                                                              'NO', wSqlGrabaInterface, 'UPDATE',
                                                                              'v:\sbtpro\icdata\ ', 'iciqty01',
                                                                              '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                              RPAD(NEW.bodega, 3, ' ') ||
                                                                              RPAD(NEW.ubicacion, 4, ' ') ||
                                                                              '","Iciqty01","Item5"' || ')', NEW.item);
                                                                  END IF;
            ----------------------------------------


                                                                  IF NEW.anio_trimestre > 0 AND NEW.bodega IN
                                                                                                ('999', '000', '001',
                                                                                                 '008', '023') THEN
                                                                      IF NOT EXISTS(SELECT item
                                                                                    FROM control_inventarios.ubicaciones_trimestre
                                                                                    WHERE bodega = NEW.bodega
                                                                                      AND item = NEW.item
                                                                                      AND ubicacion = NEW.ubicacion
                                                                                      AND anio_trimestre = NEW.anio_trimestre) THEN
                                                                          PERFORM *
                                                                          FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(
                                                                                  new.item, new.bodega, new.ubicacion,
                                                                                  new.anio_trimestre, new.cantidad,
                                                                                  new.creacion_usuario);
                                                                          UPDATE control_inventarios.ubicaciones_trimestre
                                                                          SET fecha_ultimo_egreso = NOW()
                                                                          WHERE bodega = NEW.bodega
                                                                            AND item = NEW.item
                                                                            AND ubicacion = NEW.ubicacion
                                                                            AND anio_trimestre = NEW.anio_trimestre;

                                                                          --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                                                          IF New.es_psql THEN
                                                                              wSqlGrabaInterface =
                                                                                      'REPLACE issued WITH {^' ||
                                                                                      TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                                                                      '}';

                                                                              INSERT INTO sistema.interface (fecha,
                                                                                                             hora,
                                                                                                             usuarios,
                                                                                                             generador,
                                                                                                             modulo,
                                                                                                             actualizad,
                                                                                                             sql,
                                                                                                             proceso,
                                                                                                             directorio,
                                                                                                             tabla,
                                                                                                             buscar,
                                                                                                             codigo)
                                                                              VALUES (NEW.creacion_fecha,
                                                                                      NEW.creacion_hora,
                                                                                      NEW.creacion_usuario, 'LINUX',
                                                                                      '$PTOVENTA', 'NO',
                                                                                      wSqlGrabaInterface, 'UPDATE',
                                                                                      'v:\sbtpro\icdata\ ', 'ictrim01',
                                                                                      '=SEEK([' ||
                                                                                      RPAD(NEW.item, 15, ' ') ||
                                                                                      RPAD(NEW.bodega, 3, ' ') ||
                                                                                      RPAD(NEW.ubicacion, 4, ' ') ||
                                                                                      LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                                                      '],[Ictrim01],[IteLocStor]' ||
                                                                                      ')', NEW.item);
                                                                          END IF;
                                                                          ----------------------------------------

                                                                      ELSE
                                                                          UPDATE control_inventarios.ubicaciones_trimestre
                                                                          SET existencia          = existencia + NEW.cantidad,
                                                                              fecha_ultimo_egreso = NOW()
                                                                          WHERE bodega = NEW.bodega
                                                                            AND item = NEW.item
                                                                            AND ubicacion = NEW.ubicacion
                                                                            AND anio_trimestre = NEW.anio_trimestre;

                                                                          --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                                                          IF New.es_psql THEN
                                                                              wSqlGrabaInterface =
                                                                                      'REPLACE tonhand WITH tonhand +' ||
                                                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                                      ','
                                                                                          || 'issued WITH {^' ||
                                                                                      TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                                                                      '}';

                                                                              INSERT INTO sistema.interface (fecha,
                                                                                                             hora,
                                                                                                             usuarios,
                                                                                                             generador,
                                                                                                             modulo,
                                                                                                             actualizad,
                                                                                                             sql,
                                                                                                             proceso,
                                                                                                             directorio,
                                                                                                             tabla,
                                                                                                             buscar,
                                                                                                             codigo)
                                                                              VALUES (NEW.creacion_fecha,
                                                                                      NEW.creacion_hora,
                                                                                      NEW.creacion_usuario, 'LINUX',
                                                                                      '$PTOVENTA', 'NO',
                                                                                      wSqlGrabaInterface, 'UPDATE',
                                                                                      'v:\sbtpro\icdata\ ', 'ictrim01',
                                                                                      '=SEEK([' ||
                                                                                      RPAD(NEW.item, 15, ' ') ||
                                                                                      RPAD(NEW.bodega, 3, ' ') ||
                                                                                      RPAD(NEW.ubicacion, 4, ' ') ||
                                                                                      LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                                                      '],[Ictrim01],[IteLocStor]' ||
                                                                                      ')', NEW.item);
                                                                          END IF;
                                                                          ----------------------------------------
                                                                      END IF;
                                                                  END IF;

            -- Archivo de Items
                                                                  UPDATE control_inventarios.items
                                                                  SET existencia               = existencia + NEW.cantidad,
                                                                      cantidad_vendida_periodo = cantidad_vendida_periodo + (NEW.cantidad * -1),
                                                                      valor_vendido_periodo    = valor_vendido_periodo + (Lv_Extprice * -1),
                                                                      cantidad_vendida_ano     = cantidad_vendida_ano + (NEW.cantidad * -1),
                                                                      valor_vendido_ano        = valor_vendido_ano + (Lv_Extprice * -1),
                                                                      ultima_venta             = NOW(),
                                                                      primera_venta            = CASE WHEN primera_venta IS NULL THEN NOW() ELSE primera_venta END
                                                                  WHERE item = NEW.item
                                                                  RETURNING primera_venta INTO Ld_primera_venta;

            --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                                                  IF New.es_psql THEN
                                                                      wSqlGrabaInterface =
                                                                              'REPLACE ionhand WITH ionhand +' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                              ','
                                                                                  || 'ilsale WITH {^' ||
                                                                              TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '},'
                                                                                  || 'ipslqt WITH ipslqt+' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad * -1, '9999999.999')) ||
                                                                              ','
                                                                                  || 'ipslvl WITH ipslvl+' ||
                                                                              TRIM(TO_CHAR(Lv_Extprice * -1, '9999999999.99999')) ||
                                                                              ','
                                                                                  || 'iyslqt WITH iyslqt+' ||
                                                                              TRIM(TO_CHAR(NEW.cantidad * -1, '9999999.999')) ||
                                                                              ','
                                                                                  || 'iyslvl WITH iyslvl+' ||
                                                                              TRIM(TO_CHAR(Lv_Extprice * -1, '9999999999.99999')) ||
                                                                              ','
                                                                                  || 'primeravta WITH {^' ||
                                                                              TO_CHAR(Ld_primera_venta, 'YYYY/MM/DD') ||
                                                                              '}';

                                                                      INSERT INTO sistema.interface (fecha, hora,
                                                                                                     usuarios,
                                                                                                     generador, modulo,
                                                                                                     actualizad, sql,
                                                                                                     proceso,
                                                                                                     directorio, tabla,
                                                                                                     buscar, codigo)
                                                                      VALUES (NEW.creacion_fecha, NEW.creacion_hora,
                                                                              NEW.creacion_usuario, 'LINUX',
                                                                              '$PTOVENTA', 'NO', wSqlGrabaInterface,
                                                                              'UPDATE', 'v:\sbtpro\icdata\ ',
                                                                              'icitem01',
                                                                              '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                              '","Icitem01","Item"' || ')', NEW.item);
                                                                  END IF;
            ----------------------------------------


            -- EGRESOS Y REINGRESOS
            WHEN 'EGRESO','REINGRES' THEN UPDATE control_inventarios.items
                                          SET existencia             = existencia + NEW.cantidad,
                                              cantidad_usada_periodo = cantidad_usada_periodo + NEW.cantidad * -1,
                                              cantidad_usada_ano     = cantidad_usada_ano + NEW.cantidad * -1,
                                              valor_usado_periodo    = valor_usado_periodo + (NEW.cantidad * NEW.costo) * -1,
                                              valor_usado_ano        = valor_usado_ano + (NEW.cantidad * NEW.costo) * -1,
                                              ultima_entrega         = CASE WHEN NEW.cantidad < 0 THEN NOW() ELSE ultima_entrega END
                                          WHERE item = NEW.item;

                                          UPDATE control_inventarios.bodegas
                                          SET existencia             = existencia + NEW.cantidad,
                                              ultima_venta           = NOW(),
                                              cantidad_usada_periodo = cantidad_usada_periodo + NEW.cantidad * -1,
                                              cantidad_usada_ano     = cantidad_usada_ano + NEW.cantidad * -1,
                                              valor_usado_periodo    = valor_usado_periodo + (NEW.cantidad * NEW.costo) * -1,
                                              valor_usado_ano        = valor_usado_ano + (NEW.cantidad * NEW.costo) * -1
                                          WHERE bodega = NEW.bodega
                                            AND item = NEW.item;

                                          IF NOT FOUND THEN
                                              RAISE EXCEPTION '%No existe regisro en bodega para actualizar. (EGRESO, REINGRES)', NEW.item;
                                          END IF;

                                          UPDATE control_inventarios.ubicaciones
                                          SET existencia = existencia + NEW.cantidad
                                          WHERE bodega = NEW.bodega
                                            AND item = NEW.item
                                            AND ubicacion = NEW.ubicacion;

            -- Si el articulo no existe
                                          IF NOT FOUND THEN
                                              RAISE EXCEPTION '%No existe regisro en ubicaciones para actualizar. (EGRESO, REINGRES)', NEW.item;
                                          END IF;

                                          IF NEW.anio_trimestre > 0 AND
                                             NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                                              UPDATE control_inventarios.ubicaciones_trimestre
                                              SET existencia = existencia + NEW.cantidad
                                              WHERE bodega = NEW.bodega
                                                AND item = NEW.item
                                                AND ubicacion = NEW.ubicacion
                                                AND anio_trimestre = NEW.anio_trimestre;

                                              -- Si el articulo no existe
                                              IF NOT FOUND THEN
                                                  RAISE EXCEPTION '%No existe regisro en ubicaciones_trimestre para actualizar. (EGRESO, REINGRES)', NEW.item;
                                              END IF;
                                          END IF;

            --LWO 2014/09/24 EGRESOS PRODUCCION
            WHEN 'EGRE ORDE' THEN PERFORM *
                                  FROM control_inventarios.transacciones_procesa_entregas(NEW.referencia, NEW.fecha,
                                                                                          NEW.item, NEW.cantidad * -1,
                                                                                          NEW.bodega, NEW.ubicacion,
                                                                                          NEW.creacion_usuario,
                                                                                          NEW.creacion_fecha,
                                                                                          NEW.creacion_hora,
                                                                                          NEW.es_psql);

            --LWO 2017/05/15 INGRESOS PRODUCCION PROCESO, INGRESO PRODUCCION TERMINADOS, DEVOLUCIONES A PLANTA
            WHEN 'INGR PP','INGR PT','DEVO PLAN'
                THEN --PERFORM * From control_inventarios.transacciones_recepciones_devoluciones_planta(NEW.referencia, NEW.fecha, NEW.item, NEW.tipo_movimiento, NEW.cantidad, NEW.bodega, NEW.ubicacion, NEW.creacion_usuario, NEW.creacion_fecha, NEW.creacion_hora, NEW.desperdicio, NEW.es_psql);
                --LWO 2017/12/22. Se agrega el trimestre.
                    PERFORM *
                    FROM control_inventarios.transacciones_recepciones_devoluciones_planta(NEW.referencia, NEW.fecha,
                                                                                           NEW.item,
                                                                                           NEW.tipo_movimiento,
                                                                                           NEW.cantidad, NEW.bodega,
                                                                                           NEW.ubicacion,
                                                                                           NEW.creacion_usuario,
                                                                                           NEW.creacion_fecha,
                                                                                           NEW.creacion_hora,
                                                                                           NEW.desperdicio, NEW.es_psql,
                                                                                           NEW.anio_trimestre);

            --LWO 2017/10/25. APERTURA DE ORDENES DE PRODUCCION
            WHEN 'APER ORDE' THEN PERFORM *
                                  FROM control_inventarios.transacciones_creacion_ordenes_produccion(NEW.item,
                                                                                                     NEW.cantidad,
                                                                                                     NEW.creacion_usuario,
                                                                                                     NEW.creacion_fecha,
                                                                                                     NEW.creacion_hora,
                                                                                                     NEW.es_psql);

            WHEN 'MODI ORDE' THEN

            WHEN 'CERR ORDE' THEN

            --LWO 2017/10/25. REAPERTURA DE ORDENES DE PRODUCCION
            WHEN 'REAP ORDE' THEN PERFORM *
                                  FROM control_inventarios.transacciones_reapertura_ordenes_produccion(NEW.item,
                                                                                                       NEW.cantidad,
                                                                                                       NEW.creacion_usuario,
                                                                                                       NEW.creacion_fecha,
                                                                                                       NEW.creacion_hora,
                                                                                                       NEW.es_psql);

            --LWO 2018/07/03. APROVECHAMIENTO DE ZETAS. RECEPCIONES QUE SE HACEN EN PIEZAS DE LAS SOBRAS.
            WHEN 'RECZ ORDE' THEN PERFORM *
                                  FROM control_inventarios.transacciones_recepciones_zetas(NEW.referencia, NEW.item,
                                                                                           NEW.fecha, NEW.cantidad,
                                                                                           NEW.es_psql,
                                                                                           NEW.creacion_usuario);

            WHEN 'COMP EXT' THEN SELECT existencia, es_fabricado
                                 INTO wExistencia, _es_fabricado
                                 FROM control_inventarios.items
                                 WHERE item = new.item;

            -- MP 20210527 por indicaciones del Ing. Marco Orellana segun mail, el costo promedio de los items que comiencen con 1U o 55
            --se calculan de la siguiente forma
                                 IF LEFT(NEW.item, 2) = ANY ('{1U,55}'::TEXT[]) THEN
                                     IF _es_fabricado THEN
                                         UPDATE control_inventarios.items AS i
                                         SET costo_promedio =
                                                 ((i.existencia * i.costo_promedio) + (new.cantidad * i.costo_estandar))
                                                     / (i.existencia + new.cantidad)
                                         WHERE i.item = new.item
                                         RETURNING i.costo_estandar INTO _costo_estandar;

                                     ELSE
                                         -- MP 20210531 se iguala el costo_estandar con costo promedio según analisis con Ing. orellana
                                         UPDATE control_inventarios.items AS i
                                         SET costo_promedio =
                                             ((i.existencia * i.costo_promedio) + (new.cantidad * new.costo))
                                                 / (i.existencia + new.cantidad)
                                           -- MP 20210609 11:56 Ing. solicita que costo_estandar sea el precio ingresado (precio factura) para items 1U..., 55... y _es_fabricado = FALSE
                                           --, costo_estandar = ((i.existencia * i.costo_promedio) + (new.cantidad * new.costo))
                                           --                   / (i.existencia + new.cantidad)
                                           , costo_estandar = new.costo
                                         WHERE i.item = new.item
                                         RETURNING i.costo_estandar INTO _costo_estandar;

                                     END IF;

                                     --MP 2021-06-14 a peticion de Ing. Orellana y Sra. Monserrat cambio el costo digitado por el costo_standar para
                                     --items LEFT(NEW.item, 2) = ANY('{1U,55}'::TEXT[])
                                     NEW.costo = _costo_estandar;
                                     --

                                 ELSE

                                     IF wExistencia + new.cantidad > 0 THEN -- calculo normal
                                         UPDATE control_inventarios.items
                                         SET costo_promedio=((existencia * costo_promedio) + (new.cantidad * new.costo)) /
                                                            (existencia + new.cantidad)
                                         WHERE item = new.item;

                                     END IF;

                                 END IF;

                                 UPDATE control_inventarios.items
                                 SET ultimo_costo=new.costo,
                                     ultima_recepcion=NOW(),
                                     cantidad_recibida_periodo=cantidad_recibida_periodo + new.cantidad,
                                     valor_recibido_periodo=valor_recibido_periodo + (new.cantidad * new.costo),
                                     cantidad_recibida_ano=cantidad_recibida_ano + new.cantidad,
                                     valor_recibido_ano=valor_recibido_ano + (new.cantidad * new.costo),
                                     existencia=existencia + new.cantidad,
                                     primera_recepcion_999 = CASE
                                                                 WHEN LEFT(NEW.item, 2) = ANY ('{1U,55}'::TEXT[]) AND
                                                                      primera_recepcion_999 IS NULL AND
                                                                      new.bodega = '999'
                                                                     THEN CURRENT_DATE
                                                                 ELSE primera_recepcion_999
                                         END --LWO 202-10-24. Agregado para los items que son producidos afuera
                                 WHERE item = new.item
                                 RETURNING primera_recepcion_999 INTO Ld_Primera_Recepcion_999;


                                 SELECT costo_promedio, costo_estandar
                                 INTO wCostoPromedio,wcosto_estandar
                                 FROM control_inventarios.items
                                 WHERE item = new.item;

            --MDC 12/Nov/2020 Grabar el costo estandard igual al costo promedio cuando se realice compras directamente en las bodegas
            --'999','000','001','008','023' ya que son items producidos totalmente fuera de la fábrica,
            --según mail enviado por Ing. Orellana el 11/Nov/2020

            -- MP 20210531 segun analisis con ing. Orellana se comenta la actualización de costo estandar, para ponerlo en el proceso de actualización
            -- de costo promedio, para items 1U,55 y que _es_fabricado = FALSE
            -- IF NEW.bodega IN ('999','000','001','008','023') AND LEFT(new.item, 2) = '55' THEN
            --		UPDATE control_inventarios.items i SET costo_estandar = wCostoPromedio WHERE i.item = new.item;
            -- END IF;
            -- MP 20210531

            --LWO 2014/09/30 Graba en la interface la actualizacion del icitem01
            --MDC 12/Nov/2020 Grabar también el costo standard en la tabla del icitem01

                                 wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                 wSqlGrabaInterface = 'REPLACE avgcost   WITH ' ||
                                                      TRIM(TO_CHAR(wCostoPromedio, '9999999999.99999')) || ','
                                                          || 'stdcost WITH ' ||
                                                      TRIM(TO_CHAR(wcosto_estandar, '9999999999.99999')) ||
                                                      ',' --mp 20230912 cambio con costo standar   wCostoPromedio
                                                          || 'lstcost WITH ' ||
                                                      TRIM(TO_CHAR(NEW.costo, '9999999999.99999')) || ','
                                                          || 'ilrecv WITH ' || wFechaGrabaVisual || ','
                                                          || 'ptdrcqt WITH ptdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ptdrcvl WITH ptdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                          || 'ytdrcqt WITH ytdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ytdrcvl WITH ytdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                          || 'ionhand WITH ionhand+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'primrec999 WITH ' || CASE
                                                                                       WHEN Ld_Primera_Recepcion_999 IS NULL
                                                                                           THEN '{}'
                                                                                       ELSE '{^' || TO_CHAR(Ld_Primera_Recepcion_999::date, 'YYYY/MM/DD') || '}' END; --LWO 202-10-24. Agregado para los items que son producidos afuera

                                 INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                sql, proceso, directorio, tabla, buscar, codigo)
                                 VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                         'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                         'icitem01',
                                         '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                         NEW.item);
            ----------------------------------------

                                 UPDATE control_inventarios.bodegas
                                 SET existencia=existencia + new.cantidad,
                                     ordenes_compra=ordenes_compra - new.cantidad,
                                     ultima_recepcion=NOW(),
                                     cantidad_recibida_periodo=cantidad_recibida_periodo + new.cantidad,
                                     valor_recibido_periodo=valor_recibido_periodo + (new.cantidad * new.costo),
                                     cantidad_recibida_ano=cantidad_recibida_ano + new.cantidad,
                                     valor_recibido_ano=valor_recibido_ano + (new.cantidad * new.costo)
                                 WHERE item = new.item
                                   AND bodega = new.bodega;

                                 IF NOT FOUND THEN
                                     INSERT INTO control_inventarios.bodegas
                                     (item, bodega, existencia, ordenes_compra, pedidos_clientes, ordenes_trabajo,
                                      ultima_recepcion, codigo_proveedor, creacion_usuario,
                                      creacion_fecha, creacion_hora, valor_usado_periodo, valor_vendido_periodo,
                                      cantidad_usada_periodo, cantidad_vendida_periodo, valor_usado_ano,
                                      valor_vendido_ano,
                                      cantidad_usada_ano, cantidad_vendida_ano, cantidad_recibida_periodo,
                                      valor_recibido_periodo, cantidad_recibida_ano, valor_recibido_ano)
                                     VALUES (NEW.item, NEW.bodega, NEW.cantidad, 0, 0, 0, NOW(),
                                             SUBSTRING(NEW.referencia, 19, 6), NEW.creacion_usuario, NEW.creacion_fecha,
                                             NEW.creacion_hora, 0, 0, 0, 0, 0, 0, 0, 0,
                                             NEW.cantidad, new.cantidad * new.costo, NEW.cantidad,
                                             new.cantidad * new.costo);
                                 ELSE

                                     --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                     wSqlGrabaInterface = 'REPLACE lonhand WITH lonhand+' ||
                                                          TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                              || 'lonordr WITH lonordr-' ||
                                                          TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                              || 'lrecv WITH ' || wFechaGrabaVisual || ','
                                                              || 'ptdrcqt WITH ptdrcqt+' ||
                                                          TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                              || 'ptdrcvl WITH ptdrcvl+' ||
                                                          TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) ||
                                                          ','
                                                              || 'ytdrcqt WITH ytdrcqt+' ||
                                                          TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                              || 'ytdrcvl WITH ytdrcvl+' ||
                                                          TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999'));


                                     INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                    actualizad, sql, proceso, directorio, tabla, buscar,
                                                                    codigo)
                                     VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                             'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                             'iciloc01',
                                             '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                             '","Iciloc01","Item1"' || ')', NEW.item);
                                 END IF;

            --Pendiente de interfas saver que modulo lo inserto
            --**

                                 UPDATE control_inventarios.ubicaciones
                                 SET existencia=existencia + new.cantidad
                                 WHERE item = new.item
                                   AND bodega = new.bodega
                                   AND ubicacion = new.ubicacion;

                                 IF NOT FOUND THEN
                                     PERFORM *
                                     FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega,
                                                                                          new.ubicacion, new.cantidad,
                                                                                          new.creacion_usuario);
                                 ELSE
                                     --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                     wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand + ' ||
                                                          TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                     INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                    actualizad, sql, proceso, directorio, tabla, buscar,
                                                                    codigo)
                                     VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                             'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                             'iciqty01',
                                             '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                             RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                                 END IF;

            --MDC 12/Nov/2020 Actualizar Ubicaciones por Trimestre cuando se realice las compras directas a las bodegas '999','000','001','008','023'
                                 IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                                     IF NOT EXISTS(SELECT item
                                                   FROM control_inventarios.ubicaciones_trimestre
                                                   WHERE bodega = NEW.bodega
                                                     AND item = NEW.item
                                                     AND ubicacion = NEW.ubicacion
                                                     AND anio_trimestre = NEW.anio_trimestre) THEN
                                         PERFORM *
                                         FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item,
                                                                                                        new.bodega,
                                                                                                        new.ubicacion,
                                                                                                        new.anio_trimestre,
                                                                                                        new.cantidad,
                                                                                                        new.creacion_usuario);
                                         UPDATE control_inventarios.ubicaciones_trimestre
                                         SET fecha_ultimo_egreso = NOW()
                                         WHERE bodega = NEW.bodega
                                           AND item = NEW.item
                                           AND ubicacion = NEW.ubicacion
                                           AND anio_trimestre = NEW.anio_trimestre;

                                         --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                         IF New.es_psql THEN
                                             wSqlGrabaInterface =
                                                     'REPLACE issued WITH {^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                                     '}';

                                             INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                            actualizad, sql, proceso, directorio, tabla,
                                                                            buscar, codigo)
                                             VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario,
                                                     'LINUX', '$PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                     'v:\sbtpro\icdata\ ', 'ictrim01',
                                                     '=SEEK([' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                     RPAD(NEW.ubicacion, 4, ' ') ||
                                                     LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                     '],[Ictrim01],[IteLocStor]' || ')', NEW.item);
                                         END IF;
                                         ----------------------------------------

                                     ELSE
                                         UPDATE control_inventarios.ubicaciones_trimestre
                                         SET existencia          = existencia + NEW.cantidad,
                                             fecha_ultimo_egreso = NOW()
                                         WHERE bodega = NEW.bodega
                                           AND item = NEW.item
                                           AND ubicacion = NEW.ubicacion
                                           AND anio_trimestre = NEW.anio_trimestre;

                                         --LWO 2018/09/25 Graba en la interface la actualizacion del icitem01
                                         IF New.es_psql THEN
                                             wSqlGrabaInterface = 'REPLACE tonhand WITH tonhand +' ||
                                                                  TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                                      || 'issued WITH {^' ||
                                                                  TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';

                                             INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                            actualizad, sql, proceso, directorio, tabla,
                                                                            buscar, codigo)
                                             VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario,
                                                     'LINUX', '$PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                     'v:\sbtpro\icdata\ ', 'ictrim01',
                                                     '=SEEK([' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                     RPAD(NEW.ubicacion, 4, ' ') ||
                                                     LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                     '],[Ictrim01],[IteLocStor]' || ')', NEW.item);
                                         END IF;
                                         ----------------------------------------
                                     END IF;
                                 END IF;

            WHEN 'DEVO EXT' THEN UPDATE control_inventarios.items
                                 SET cantidad_recibida_periodo=cantidad_recibida_periodo + new.cantidad,
                                     valor_recibido_periodo=valor_recibido_periodo + (new.cantidad * new.costo),
                                     cantidad_recibida_ano=cantidad_recibida_ano + new.cantidad,
                                     valor_recibido_ano=valor_recibido_ano + (new.cantidad * new.costo),
                                     existencia=existencia + new.cantidad
                                 WHERE item = new.item;

            --LWO 2014/09/30 Graba en la interface
                                 wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                 wSqlGrabaInterface = 'REPLACE ptdrcqt WITH ptdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ptdrcvl WITH ptdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                          || 'ytdrcqt WITH ytdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ytdrcvl WITH ytdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                          || 'ionhand WITH ionhand+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                 INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                sql, proceso, directorio, tabla, buscar, codigo)
                                 VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                         'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                         'icitem01',
                                         '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                         NEW.item);
            ----------------------------------------

                                 UPDATE control_inventarios.bodegas
                                 SET existencia=existencia + new.cantidad,
                                     cantidad_recibida_periodo=cantidad_recibida_periodo + new.cantidad,
                                     valor_recibido_periodo=valor_recibido_periodo + (new.cantidad * new.costo),
                                     cantidad_recibida_ano=cantidad_recibida_ano + new.cantidad,
                                     valor_recibido_ano=valor_recibido_ano + (new.cantidad * new.costo)
                                 WHERE item = new.item
                                   AND bodega = new.bodega;

            --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                 wSqlGrabaInterface = 'REPLACE lonhand WITH lonhand+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ptdrcqt WITH ptdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ptdrcvl WITH ptdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                          || 'ytdrcqt WITH ytdrcqt+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                          || 'ytdrcvl WITH ytdrcvl+' ||
                                                      TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999'));


                                 INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                sql, proceso, directorio, tabla, buscar, codigo)
                                 VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                         'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                         'iciloc01', '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                     '","Iciloc01","Item1"' || ')', NEW.item);
            ----------------------------------------

                                 UPDATE control_inventarios.ubicaciones
                                 SET existencia=existencia + new.cantidad
                                 WHERE item = new.item
                                   AND bodega = new.bodega
                                   AND ubicacion = new.ubicacion;

            --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                 wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand + ' ||
                                                      TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                 INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                sql, proceso, directorio, tabla, buscar, codigo)
                                 VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                         'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                         'iciqty01', '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                     RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')',
                                         NEW.item);

            -- AJUSTES AL COSTO
            WHEN 'AJUS COST-','AJUS COST+' THEN -- JG 2025/01/23 Se actualiza el costo promedio del item
            IF new.tipo_movimiento = 'AJUS COST+' THEN
                WITH t AS (
                    UPDATE control_inventarios.items i
                        SET costo_promedio = new.costo
                        WHERE item = new.item
                        RETURNING i.costo_promedio, i.item)
                INSERT
                INTO sistema.interface (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
                SELECT 'AUDITORIA',
                       'UPDATE1',
                       'Icitem01',
                       NEW.creacion_usuario,
                       'V:\SBTPRO\ICDATA\ ',
                       '',
                       'UPDATE V:\SBTPRO\ICDATA\Icitem01 ' ||
                       'SET avgcost = ' || t.costo_promedio || ' ' ||
                       'Where item = [' || RPAD(t.item, 15, ' ') || '] '
                FROM t;
            END IF;

            -- AJUSTES DE INVENTARIO
            WHEN 'AJUS CANT-','AJUS CANT+' THEN -- EXISTENCIAS POR TRIMESTRE
            --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                    UPDATE control_inventarios.ubicaciones_trimestre
                    SET existencia = existencia + NEW.cantidad
                    WHERE bodega = NEW.bodega
                      AND item = NEW.item
                      AND ubicacion = NEW.ubicacion
                      AND anio_trimestre = NEW.anio_trimestre;
                    -- Si el articulo no existe
                    IF NOT FOUND THEN
                        PERFORM *
                        FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item, new.bodega,
                                                                                       new.ubicacion,
                                                                                       new.anio_trimestre, new.cantidad,
                                                                                       new.creacion_usuario);
                    ELSE
                        IF New.es_psql THEN
                            --LWO 2014/09/30 Graba en la interface la actualizacin del ictrim01
                            wSqlGrabaInterface =
                                    'REPLACE tonhand WITH tonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                           proceso, directorio, tabla, buscar, codigo)
                            VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX', 'COMPRAS',
                                    'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'ictrim01',
                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                    RPAD(NEW.ubicacion, 4, ' ') || LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                    '","Ictrim01","IteLocStor"' || ')', NEW.item);
                        END IF;
                    END IF;
                END IF;


                -- EXISTENCIAS POR UBICACION
                UPDATE control_inventarios.ubicaciones
                SET existencia = existencia + NEW.cantidad
                WHERE bodega = NEW.bodega
                  AND item = NEW.item
                  AND ubicacion = NEW.ubicacion;
                -- Si el articulo no existe
                IF NOT FOUND THEN
                    /*pedir monica quitar el inteface*/

                    PERFORM *
                    FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega, new.ubicacion,
                                                                         new.cantidad, new.creacion_usuario);
                ELSE
                    IF New.es_psql THEN
                        --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                        wSqlGrabaInterface =
                                'REPLACE qonhand WITH qonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                       proceso, directorio, tabla, buscar, codigo)
                        VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                    END IF;
                END IF;

                -- EXISTENCIAS POR BODEGA
                UPDATE control_inventarios.bodegas
                SET existencia = existencia + NEW.cantidad
                WHERE bodega = NEW.bodega
                  AND item = NEW.item;
                -- Si el articulo no existe
                IF NOT FOUND THEN
                    INSERT INTO control_inventarios.bodegas (bodega, item, existencia, creacion_usuario)
                    VALUES (NEW.bodega, NEW.item, NEW.cantidad, NEW.creacion_usuario);
                ELSE

                    IF New.es_psql THEN

                        --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                        wSqlGrabaInterface =
                                'REPLACE lonhand WITH lonhand+' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                       proceso, directorio, tabla, buscar, codigo)
                        VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                '","Iciloc01","Item1"' || ')', NEW.item);
                        ----------------------------------------
                    END IF;
                END IF;

                -- ITEMS
                UPDATE control_inventarios.items SET existencia = existencia + NEW.cantidad WHERE item = NEW.item;

                IF New.es_psql THEN

                    --LWO 2014/09/30 Graba en la interface
                    wSqlGrabaInterface = 'REPLACE ionhand WITH ionhand+' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql, proceso,
                                                   directorio, tabla, buscar, codigo)
                    VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                            wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')', NEW.item);
                    ----------------------------------------
                END IF;

            --LWO 2017/07/06. RECEPCION DE TRANSFERENCIAS FUERA DEL PERIODO (JR,JI): Se suma la existencia y se resta del transito.
            WHEN 'RECE CANT-','RECE CANT+' THEN UPDATE control_inventarios.items
                                                SET existencia = existencia + NEW.cantidad,
                                                    transito   = transito - NEW.cantidad
                                                WHERE item = NEW.item;

                                                IF New.es_psql THEN
                                                    --LWO 2014/09/30 Graba en la interface
                                                    wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                                    wSqlGrabaInterface = 'REPLACE ionhand WITH ionhand+' ||
                                                                         TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                         ',' || 'transtra WITH transtra-' ||
                                                                         TRIM(TO_CHAR(NEW.cantidad, '9999999999.99999'));
                                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador,
                                                                                   modulo, actualizad, sql, proceso,
                                                                                   directorio, tabla, buscar, codigo)
                                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX',
                                                            'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                            'v:\sbtpro\icdata\ ', 'icitem01',
                                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                            '","Icitem01","Item"' || ')', NEW.item);
                                                END IF;

            -- EXISTENCIAS POR BODEGA
                                                UPDATE control_inventarios.bodegas
                                                SET existencia = existencia + NEW.cantidad,
                                                    transito   = transito - NEW.cantidad
                                                WHERE bodega = NEW.bodega
                                                  AND item = NEW.item;

                                                IF NOT FOUND THEN
                                                    INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, existencia, transito)
                                                    VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, NEW.cantidad,
                                                            NEW.cantidad * -1);
                                                ELSE
                                                    IF New.es_psql THEN
                                                        --LWO 2014/09/30 Graba en la interface
                                                        wFechaGrabaVisual = '{^' || TO_CHAR(NOW(), 'YYYY/MM/DD') || '}';
                                                        wSqlGrabaInterface = 'REPLACE lonhand WITH lonhand+' ||
                                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                             ','
                                                                                 || 'transtra WITH transtra-' ||
                                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999999.99999'));
                                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador,
                                                                                       modulo, actualizad, sql, proceso,
                                                                                       directorio, tabla, buscar,
                                                                                       codigo)
                                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario,
                                                                'LINUX', 'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                                'v:\sbtpro\icdata\ ', 'iciloc01',
                                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                RPAD(NEW.bodega, 3, ' ') || '","Iciloc01","Item1"' ||
                                                                ')', NEW.item);
                                                    END IF;
                                                END IF;

            -- EXISTENCIAS POR UBICACION
                                                UPDATE control_inventarios.ubicaciones
                                                SET existencia = existencia + NEW.cantidad,
                                                    transito   = transito - NEW.cantidad
                                                WHERE bodega = NEW.bodega
                                                  AND item = NEW.item
                                                  AND ubicacion = NEW.ubicacion;
                                                IF NOT found THEN
                                                    PERFORM *
                                                    FROM control_inventarios.item_ubicacion_creacion_fnc(new.item,
                                                                                                         new.bodega,
                                                                                                         new.ubicacion,
                                                                                                         NEW.cantidad,
                                                                                                         new.creacion_usuario);
                                                    UPDATE control_inventarios.ubicaciones
                                                    SET transito = transito - NEW.cantidad
                                                    WHERE bodega = NEW.bodega
                                                      AND item = NEW.item
                                                      AND ubicacion = NEW.ubicacion;

                                                    IF New.es_psql THEN
                                                        --LWO 2014/09/30 Graba en la interface
                                                        wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                                        wSqlGrabaInterface = 'REPLACE transtra WITH transtra-' ||
                                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999999.99999'));
                                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador,
                                                                                       modulo, actualizad, sql, proceso,
                                                                                       directorio, tabla, buscar,
                                                                                       codigo)
                                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario,
                                                                'LINUX', 'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                                'v:\sbtpro\icdata\ ', 'iciqty01',
                                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                RPAD(NEW.bodega, 3, ' ') ||
                                                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' ||
                                                                ')', NEW.item);
                                                    END IF;
                                                ELSE
                                                    IF New.es_psql THEN
                                                        --LWO 2014/09/30 Graba en la interface
                                                        wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                                        wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand+' ||
                                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) ||
                                                                             ','
                                                                                 || 'transtra WITH transtra-' ||
                                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999999.99999'));
                                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador,
                                                                                       modulo, actualizad, sql, proceso,
                                                                                       directorio, tabla, buscar,
                                                                                       codigo)
                                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario,
                                                                'LINUX', 'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                                'v:\sbtpro\icdata\ ', 'iciqty01',
                                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') ||
                                                                RPAD(NEW.bodega, 3, ' ') ||
                                                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' ||
                                                                ')', NEW.item);
                                                    END IF;
                                                END IF;


            WHEN 'INGR ORDE' THEN UPDATE control_inventarios.items
                                  SET costo_promedio = 0.00001
                                  WHERE item = NEW.item
                                    AND LEFT(NEW.item, 1) = 'Z'
                                    AND costo_promedio <= 0;

                                  IF FOUND THEN
                                      IF New.es_psql THEN
                                          wSqlGrabaInterface =
                                                  'REPLACE avgcost WITH IIF(Ionhand>=0,((ionhand*avgcost)+(' ||
                                                  TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || '*' ||
                                                  TRIM(TO_CHAR(NEW.costo, '9999999999.99999')) || '))/(ionhand+' ||
                                                  TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ')' || ',avgcost)';

                                          INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                         actualizad, sql, proceso, directorio, tabla,
                                                                         buscar, codigo)
                                          VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                                  'COMISARIATO', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                  'v:\sbtpro\icdata\ ', 'icitem01',
                                                  '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                                  NEW.item);
                                      END IF;
                                  END IF;


                                  UPDATE control_inventarios.items
                                  SET existencia                = existencia + NEW.cantidad,
                                      cantidad_recibida_periodo = cantidad_recibida_periodo + NEW.cantidad,
                                      cantidad_recibida_ano     = cantidad_recibida_ano + NEW.cantidad,
                                      ultima_recepcion          = NOW()
                                  WHERE item = NEW.item;

                                  IF New.es_psql THEN
                                      wSqlGrabaInterface =
                                              'REPLACE ilrecv WITH ' || '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                              '}' || ','
                                                  || 'ptdrcqt WITH ptdrcqt+' ||
                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                  || 'ptdrcvl WITH ptdrcvl+' ||
                                              TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                  || 'ytdrcqt WITH ytdrcqt+' ||
                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                  || 'ytdrcvl WITH ytdrcvl+' ||
                                              TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) || ','
                                                  || 'ionhand WITH ionhand+' ||
                                              TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                      INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                     actualizad, sql, proceso, directorio, tabla,
                                                                     buscar, codigo)
                                      VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                              'COMISARIATO', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                              'icitem01',
                                              '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                              NEW.item);
                                  END IF;

                                  UPDATE control_inventarios.bodegas
                                  SET existencia=existencia + new.cantidad,
                                      ultima_recepcion=NOW(),
                                      cantidad_recibida_periodo=cantidad_recibida_periodo + new.cantidad,
                                      valor_recibido_periodo=valor_recibido_periodo + (new.cantidad * new.costo),
                                      cantidad_recibida_ano=cantidad_recibida_ano + new.cantidad,
                                      valor_recibido_ano=valor_recibido_ano + (new.cantidad * new.costo)
                                  WHERE item = new.item
                                    AND bodega = new.bodega;

                                  IF NOT FOUND THEN
                                      INSERT INTO control_inventarios.bodegas
                                      (item, bodega, existencia, ultima_recepcion, creacion_usuario,
                                       creacion_fecha, creacion_hora,
                                       cantidad_recibida_periodo, valor_recibido_periodo, cantidad_recibida_ano,
                                       valor_recibido_ano)
                                      VALUES (NEW.item, NEW.bodega, NEW.cantidad, NOW(), NEW.creacion_usuario,
                                              NEW.creacion_fecha, NEW.creacion_hora,
                                              NEW.cantidad, new.cantidad * new.costo, NEW.cantidad,
                                              new.cantidad * new.costo);
                                  ELSE
                                      IF New.es_psql THEN
                                          --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                          wSqlGrabaInterface = 'REPLACE lonhand WITH lonhand+' ||
                                                               TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                                   || 'lrecv   WITH ' || '{^' ||
                                                               TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}' || ','
                                                                   || 'ptdrcqt WITH ptdrcqt+' ||
                                                               TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                                   || 'ptdrcvl WITH ptdrcvl+' ||
                                                               TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999')) ||
                                                               ','
                                                                   || 'ytdrcqt WITH ytdrcqt+' ||
                                                               TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                                                   || 'ytdrcvl WITH ytdrcvl+' ||
                                                               TRIM(TO_CHAR(NEW.cantidad * NEW.costo, '9999999999.99999'));


                                          INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                         actualizad, sql, proceso, directorio, tabla,
                                                                         buscar, codigo)
                                          VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                                  'COMPRAS', 'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ',
                                                  'iciloc01',
                                                  '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                  '","Iciloc01","Item1"' || ')', NEW.item);
                                      END IF;
                                  END IF;


                                  UPDATE control_inventarios.ubicaciones
                                  SET ultima_recepcion = NOW()
                                  WHERE item = new.item
                                    AND bodega = new.bodega
                                    AND ubicacion = new.ubicacion
                                    AND existencia = 0;

                                  IF FOUND THEN
                                      IF New.es_psql THEN
                                          --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                          wSqlGrabaInterface =
                                                  'REPLACE lrecv WITH ' || '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                                  '}';

                                          INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                         actualizad, sql, proceso, directorio, tabla,
                                                                         buscar, codigo)
                                          VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                                  'COMISARIATO', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                  'v:\sbtpro\icdata\ ', 'iciqty01',
                                                  '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                  RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')',
                                                  NEW.item);
                                      END IF;
                                  END IF;

                                  UPDATE control_inventarios.ubicaciones
                                  SET existencia=existencia + new.cantidad
                                  WHERE item = new.item
                                    AND bodega = new.bodega
                                    AND ubicacion = new.ubicacion;

                                  IF NOT FOUND THEN
                                      PERFORM *
                                      FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega,
                                                                                           new.ubicacion, new.cantidad,
                                                                                           new.creacion_usuario);

                                      UPDATE control_inventarios.ubicaciones
                                      SET ultima_recepcion = NOW()
                                      WHERE item = new.item
                                        AND bodega = new.bodega
                                        AND ubicacion = new.ubicacion;

                                      IF New.es_psql THEN
                                          --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                          wSqlGrabaInterface =
                                                  'REPLACE lrecv WITH ' || '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') ||
                                                  '}';

                                          INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                         actualizad, sql, proceso, directorio, tabla,
                                                                         buscar, codigo)
                                          VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                                  'COMISARIATO', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                  'v:\sbtpro\icdata\ ', 'iciqty01',
                                                  '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                  RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')',
                                                  NEW.item);
                                      END IF;

                                  ELSE
                                      IF New.es_psql THEN
                                          --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                          wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand + ' ||
                                                               TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                          INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                         actualizad, sql, proceso, directorio, tabla,
                                                                         buscar, codigo)
                                          VALUES (NEW.creacion_fecha, NEW.creacion_hora, NEW.creacion_usuario, 'LINUX',
                                                  'COMISARIATO', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                  'v:\sbtpro\icdata\ ', 'iciqty01',
                                                  '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                  RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')',
                                                  NEW.item);
                                      END IF;
                                  END IF;
            --*--------------------------------


            END CASE;
        RETURN NEW;
    END IF;

    --LWO 2014/09/24
    --REUBICACIONES Y TRANSFERENCIAS PUEDEN SER REGISTROS NUEVOS O MODIFICADOS.
    IF NEW.tipo_movimiento IN ('REUB CANT-', 'REUB CANT+', 'TRANSFER-', 'TRANSFER+') AND
       (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN

        --LWO 2014/09/19. Agregado estas lineas por el caso de transacciones no actualizadas, no se debe actualizar el inventario.
        IF TG_OP = 'INSERT' AND NEW.status = 'U' THEN
            DROP TABLE IF EXISTS es_vfp;
            RETURN NEW;
        END IF;
        -----------------------

        IF TG_OP = 'UPDATE' AND NEW.status = 'V' THEN --En caso de que se este anulando una transacción no actualizada.
            DROP TABLE IF EXISTS es_vfp;
            RETURN NEW;
        END IF;

        -- Actualiza el archivos de inventario
        CASE NEW.tipo_movimiento

            -- REUBICACIONES
            WHEN 'REUB CANT-','REUB CANT+' THEN IF TG_OP = 'INSERT' OR
                                                   (TG_OP = 'UPDATE' AND OLD.status = 'U' AND COALESCE(NEW.status, '') = '') THEN

                --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                    -- EXISTENCIAS POR TRIMESTRE
                    UPDATE control_inventarios.ubicaciones_trimestre
                    SET existencia = existencia + NEW.cantidad
                    WHERE bodega = NEW.bodega
                      AND item = NEW.item
                      AND ubicacion = NEW.ubicacion
                      AND anio_trimestre = NEW.anio_trimestre;

                    -- Si el articulo no existe
                    IF NOT FOUND THEN
                        PERFORM *
                        FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item, new.bodega,
                                                                                       new.ubicacion,
                                                                                       NEW.anio_trimestre, new.cantidad,
                                                                                       new.creacion_usuario);
                    ELSE
                        IF New.es_psql THEN
                            --Graba en la interface la actualizacin del iciqty01
                            wSqlGrabaInterface =
                                    'REPLACE tonhand WITH tonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                           proceso, directorio, tabla, buscar, codigo)
                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                    wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'ictrim01',
                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                    RPAD(NEW.ubicacion, 4, ' ') || LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                    '","Ictrim01","IteLocStor"' || ')', NEW.item);
                        END IF;
                    END IF;
                END IF;

                -- EXISTENCIAS POR UBICACION
                UPDATE control_inventarios.ubicaciones
                SET existencia = existencia + NEW.cantidad
                WHERE bodega = NEW.bodega
                  AND item = NEW.item
                  AND ubicacion = NEW.ubicacion;

                -- Si el articulo no existe
                IF NOT FOUND THEN
                    PERFORM *
                    FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega, new.ubicacion,
                                                                         new.cantidad, new.creacion_usuario);

                    --LWO 2018-02-14. En caso de que la existencia quede en cero, se debe blanquear el comentario en ubicaciones
                    IF new.cantidad <= 0 THEN
                        UPDATE control_inventarios.ubicaciones
                        SET comentario = NULL
                        WHERE bodega = NEW.bodega
                          AND item = NEW.item
                          AND ubicacion = NEW.ubicacion;

                        IF New.es_psql THEN
                            wSqlGrabaInterface = 'REPLACE comentario WITH []';

                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                           proceso, directorio, tabla, buscar, codigo)
                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                    wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                    RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                        END IF;

                    END IF;
                    ----------------
                ELSE
                    --LWO 2018-02-14. En caso de que la existencia quede en cero, se debe blanquear el comentario en ubicaciones
                    SELECT COALESCE(existencia, 0)
                    INTO wExistencia
                    FROM control_inventarios.ubicaciones
                    WHERE item = NEW.item
                      AND bodega = NEW.bodega
                      AND ubicacion = NEW.ubicacion;
                    IF wExistencia <= 0 THEN
                        UPDATE control_inventarios.ubicaciones
                        SET comentario = NULL
                        WHERE bodega = NEW.bodega
                          AND item = NEW.item
                          AND ubicacion = NEW.ubicacion;
                    END IF;
                    SELECT COALESCE(comentario, '')
                    INTO wComentario
                    FROM control_inventarios.ubicaciones
                    WHERE item = NEW.item
                      AND bodega = NEW.bodega
                      AND ubicacion = NEW.ubicacion;
                    ----------------

                    IF New.es_psql THEN
                        --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                        wSqlGrabaInterface =
                                'REPLACE qonhand WITH qonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999')) || ','
                                    || 'comentario WITH [' || wComentario || ']';

                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                       proceso, directorio, tabla, buscar, codigo)
                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                    END IF;
                END IF;

                -- EXISTENCIAS POR BODEGA
                UPDATE control_inventarios.bodegas
                SET existencia = existencia + NEW.cantidad
                WHERE bodega = NEW.bodega
                  AND item = NEW.item;
                -- Si el articulo no existe
                IF NOT FOUND THEN
                    --LWO 2014/09/19. Agregado para que tome la cuenta contable del mismo item de otra bodega, si no hay el item que tome el que coincide con
                    --el primer caracter del item
                    INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, existencia)
                    VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, NEW.cantidad);
                ELSE
                    IF New.es_psql THEN
                        --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                        wSqlGrabaInterface =
                                'REPLACE lonhand WITH lonhand+' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                       proceso, directorio, tabla, buscar, codigo)
                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'COMPRAS', 'NO',
                                wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                '","Iciloc01","Item1"' || ')', NEW.item);
                    END IF;
                END IF;
            END IF;

            -- TRANSFERENCIA QUE SALE
            WHEN 'TRANSFER-'
                THEN IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.status = 'U' AND NEW.status IS NULL) THEN

                    -- EXISTENCIAS POR ITEM

                    UPDATE control_inventarios.items SET existencia = existencia + NEW.cantidad WHERE item = NEW.item;

                    IF New.es_psql THEN
                        --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                        wSqlGrabaInterface =
                                'REPLACE ionhand WITH ionhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                       proceso, directorio, tabla, buscar, codigo)
                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA', 'NO',
                                wSqlGrabaInterface,
                                'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                                '=SEEK([' || RPAD(NEW.item, 15, ' ') || '], [icitem01], [item])', NEW.item);
                        ----------------------------------------
                    END IF;

                    -- EXISTENCIAS POR BODEGA
                    UPDATE control_inventarios.bodegas
                    SET existencia                  = existencia + NEW.cantidad,
                        ultimo_egreso_transferencia = NOW()
                    WHERE bodega = NEW.bodega
                      AND item = NEW.item;

                    -- Si el bodega no existe
                    IF NOT FOUND THEN
                        --LWO 2014/09/19. Agregado para que tome la cuenta contable del mismo item de otra bodega, si no hay el item que tome el que coincide con
                        --el primer caracter del item
                        INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, existencia,
                                                                 ultimo_egreso_transferencia)
                        VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, NEW.cantidad, NOW());
                    ELSE
                        IF New.es_psql THEN
                            --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                            wSqlGrabaInterface =
                                    'REPLACE ltranssale with {^' || TO_CHAR(NOW(), 'YYYY-MM-DD') || '}, ' ||
                                    'lonhand WITH lonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                           proceso, directorio, tabla, buscar, codigo)
                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA', 'NO',
                                    wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                    '","Iciloc01","Item1"' || ')', NEW.item);
                            ----------------------------------------
                        END IF;
                    END IF;

                    -- EXISTENCIAS POR UBICACION
                    UPDATE control_inventarios.ubicaciones
                    SET existencia = existencia + NEW.cantidad
                    WHERE bodega = NEW.bodega
                      AND item = NEW.item
                      AND ubicacion = NEW.ubicacion;
                    -- Si el articulo no existe

                    IF NOT FOUND THEN
                        PERFORM *
                        FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega, new.ubicacion,
                                                                             new.cantidad, new.creacion_usuario);
                    ELSE
                        IF New.es_psql THEN
                            --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                            wSqlGrabaInterface =
                                    'REPLACE qonhand WITH qonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad, sql,
                                                           proceso, directorio, tabla, buscar, codigo)
                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA', 'NO',
                                    wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                    RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                        END IF;

                    END IF;

                    --EXISTENCIAS POR TRIMESTRE
                    --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                    IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                        -- EXISTENCIAS POR trimestre
                        UPDATE control_inventarios.ubicaciones_trimestre
                        SET existencia = existencia + NEW.cantidad
                        WHERE bodega = NEW.bodega
                          AND item = NEW.item
                          AND ubicacion = NEW.ubicacion
                          AND anio_trimestre = NEW.anio_trimestre;
                        -- Si el articulo no existe

                        IF NOT FOUND THEN
                            PERFORM *
                            FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item, new.bodega,
                                                                                           new.ubicacion,
                                                                                           NEW.anio_trimestre,
                                                                                           new.cantidad,
                                                                                           new.creacion_usuario);
                        ELSE
                            IF New.es_psql THEN
                                --Graba en la interface la actualizacin del ictrim01
                                wSqlGrabaInterface =
                                        'REPLACE tonhand WITH tonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                               sql, proceso, directorio, tabla, buscar, codigo)
                                VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                        'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'ictrim01',
                                        '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                        RPAD(NEW.ubicacion, 4, ' ') || LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                        '","Ictrim01","IteLocStor"' || ')', NEW.item);
                            END IF;

                        END IF;
                    END IF;

                END IF;

            WHEN 'TRANSFER+'
                THEN --LWO 2014/09/22. Agregado estas líneas porque los almacenes en tránsito, se actualiza el campo de tránstio y no se actualiza todavia la existencia, sino
                --hasta que llegue la mercaderia y se haga la recepción.
                    SELECT tiene_transito
                    INTO WBodegaconTransito
                    FROM control_inventarios.id_bodegas
                    WHERE bodega = NEW.bodega;

                    IF TG_OP = 'INSERT'
                        OR (TG_OP = 'UPDATE' AND OLD.status = 'U' AND NEW.status IS NULL)
                        OR
                       (TG_OP = 'UPDATE' AND WBodegaconTransito AND OLD.status IS NULL) THEN --Esta ultima condicion es para la recepcion de transferencias

                        IF TG_OP = 'INSERT' AND WBodegaconTransito AND COALESCE(NEW.cantidad_recibida, 0) = 0 THEN

                            -- EXISTENCIAS POR ITEMS

                            UPDATE control_inventarios.items
                            SET transito = transito + NEW.cantidad
                            WHERE item = NEW.item;

                            IF New.es_psql THEN
                                --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                wSqlGrabaInterface = 'REPLACE transtra WITH transtra + ' ||
                                                     TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                               sql, proceso, directorio, tabla, buscar, codigo)
                                VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                        'NO', wSqlGrabaInterface,
                                        'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                                        '=SEEK([' || RPAD(NEW.item, 15, ' ') || '], [icitem01], [item])', NEW.item);
                                ----------------------------------------
                            END IF;

                            -- EXISTENCIAS POR BODEGA
                            UPDATE control_inventarios.bodegas
                            SET transito = transito + NEW.cantidad
                            WHERE bodega = NEW.bodega
                              AND item = NEW.item;

                            -- Si el bodega no existe
                            IF NOT FOUND THEN
                                --LWO 2014/09/19. Agregado para que tome la cuenta contable del mismo item de otra bodega, si no hay el item que tome el que coincide con
                                --el primer caracter del item
                                INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, transito)
                                VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, NEW.cantidad);
                            ELSE
                                IF New.es_psql THEN
                                    --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                    wSqlGrabaInterface = 'REPLACE transtra WITH transtra + ' ||
                                                         TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                            'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                            '","Iciloc01","Item1"' || ')', NEW.item);
                                    ----------------------------------------
                                END IF;

                            END IF;

                            -- Si el bodega no existe

                            -- EXISTENCIAS POR UBICACION
                            UPDATE control_inventarios.ubicaciones
                            SET transito = transito + NEW.cantidad
                            WHERE bodega = NEW.bodega
                              AND item = NEW.item
                              AND ubicacion = NEW.ubicacion;
                            -- Si el articulo no existe
                            IF NOT FOUND THEN
                                PERFORM *
                                FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega,
                                                                                     new.ubicacion, 0,
                                                                                     new.creacion_usuario);
                                UPDATE control_inventarios.ubicaciones
                                SET transito = transito + NEW.cantidad
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item
                                  AND ubicacion = NEW.ubicacion;

                            END IF;

                            IF New.es_psql THEN
                                --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                wSqlGrabaInterface = 'REPLACE transtra WITH transtra + ' ||
                                                     TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                               sql, proceso, directorio, tabla, buscar, codigo)
                                VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                        'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                        '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                        RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                            END IF;

                            --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                            IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN

                                -- EXISTENCIAS POR UBICACION
                                UPDATE control_inventarios.ubicaciones_trimestre
                                SET transito = transito + NEW.cantidad
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item
                                  AND ubicacion = NEW.ubicacion
                                  AND anio_trimestre = NEW.anio_trimestre;
                                -- Si el articulo no existe
                                IF NOT FOUND THEN
                                    PERFORM *
                                    FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item, new.bodega,
                                                                                                   new.ubicacion,
                                                                                                   NEW.anio_trimestre,
                                                                                                   0,
                                                                                                   new.creacion_usuario);
                                    UPDATE control_inventarios.ubicaciones_trimestre
                                    SET transito = transito + NEW.cantidad
                                    WHERE bodega = NEW.bodega
                                      AND item = NEW.item
                                      AND ubicacion = NEW.ubicacion
                                      AND anio_trimestre = NEW.anio_trimestre;

                                END IF;

                                IF New.es_psql THEN
                                    --Graba en la interface la actualizacin del ictrim01
                                    wSqlGrabaInterface = 'REPLACE transtra WITH transtra + ' ||
                                                         TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                            'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'ictrim01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                            RPAD(NEW.ubicacion, 4, ' ') || LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                            '","Ictrim01","IteLocStor"' || ')', NEW.item);
                                END IF;
                            END IF;

                        ELSIF (TG_OP = 'INSERT' AND WBodegaconTransito = FALSE) OR
                              (TG_OP = 'UPDATE' AND OLD.status = 'U' AND NEW.status IS NULL) THEN --REGISTROS NUEVOS O ACTUALIZACION DE TRANSFERENCIAS PENDIENTES
                        /*--*/
                        -- EXISTENCIAS POR ITEM
                            UPDATE control_inventarios.items
                            SET existencia = existencia + NEW.cantidad
                            WHERE item = NEW.item;

                            IF New.es_psql THEN
                                --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                wSqlGrabaInterface =
                                        'REPLACE ionhand WITH ionhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                               sql, proceso, directorio, tabla, buscar, codigo)
                                VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                        'NO', wSqlGrabaInterface,
                                        'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                                        '=SEEK([' || RPAD(NEW.item, 15, ' ') || '], [icitem01], [item])', NEW.item);
                                ----------------------------------------
                            END IF;

                            -- EXISTENCIAS POR BODEGA
                            UPDATE control_inventarios.bodegas
                            SET existencia                   = existencia + NEW.cantidad,
                                ultimo_ingreso_transferencia = NOW()
                            WHERE bodega = NEW.bodega
                              AND item = NEW.item;

                            -- Si el bodega no existe
                            IF NOT FOUND THEN
                                --LWO 2014/09/19. Agregado para que tome la cuenta contable del mismo item de otra bodega, si no hay el item que tome el que coincide con
                                --el primer caracter del item
                                INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, existencia,
                                                                         ultimo_ingreso_transferencia)
                                VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, NEW.cantidad, NOW());
                            ELSE
                                IF New.es_psql THEN
                                    --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                    wSqlGrabaInterface =
                                            'REPLACE ltransingr with {^' || TO_CHAR(NOW(), 'YYYY-MM-DD') || '}, ' ||
                                            'lonhand WITH lonhand + ' || TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                            'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                            '","Iciloc01","Item1"' || ')', NEW.item);
                                    ----------------------------------------
                                END IF;

                            END IF;

                            UPDATE control_inventarios.bodegas
                            SET ultima_recepcion = NEW.fecha
                            WHERE bodega = NEW.bodega
                              AND item = NEW.item
                              AND (existencia <= 0 OR ultima_recepcion IS NULL);

                            IF FOUND THEN
                                IF New.es_psql THEN
                                    --LWO 2014/09/30 Graba en la interface la actualizacion del iciloc01
                                    wSqlGrabaInterface =
                                            'REPLACE ltransingr with {^' || TO_CHAR(NOW(), 'YYYY-MM-DD') || '}';

                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                            'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                            '","Iciloc01","Item1"' || ')', NEW.item);
                                    ----------------------------------------
                                END IF;
                            END IF;

                            -- EXISTENCIAS POR UBICACION
                            UPDATE control_inventarios.ubicaciones
                            SET existencia = existencia + NEW.cantidad
                            WHERE bodega = NEW.bodega
                              AND item = NEW.item
                              AND ubicacion = NEW.ubicacion;
                            -- Si el articulo no existe
                            IF NOT FOUND THEN
                                PERFORM *
                                FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega,
                                                                                     new.ubicacion, new.cantidad,
                                                                                     new.creacion_usuario);
                            ELSE
                                IF New.es_psql THEN
                                    --LWO 2014/09/30 Graba en la interface la actualizacin del iciqty01
                                    wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand + ' ||
                                                         TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'TRANSFERENCIA',
                                            'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                            RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                                END IF;
                            END IF;

                            --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                            IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                                -- EXISTENCIAS POR UBICACION
                                UPDATE control_inventarios.ubicaciones_trimestre
                                SET existencia = existencia + NEW.cantidad
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item
                                  AND ubicacion = NEW.ubicacion
                                  AND anio_trimestre = NEW.anio_trimestre;
                                -- Si el articulo no existe
                                IF NOT FOUND THEN
                                    PERFORM *
                                    FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item, new.bodega,
                                                                                                   new.ubicacion,
                                                                                                   NEW.anio_trimestre,
                                                                                                   new.cantidad,
                                                                                                   new.creacion_usuario);
                                ELSE
                                    IF New.es_psql THEN
                                        --Graba en la interface la actualizacin del ictrim01
                                        wSqlGrabaInterface = 'REPLACE tonhand WITH tonhand + ' ||
                                                             TRIM(TO_CHAR(NEW.cantidad, '9999999.999'));

                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX',
                                                'TRANSFERENCIA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                'v:\sbtpro\icdata\ ', 'ictrim01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                RPAD(NEW.ubicacion, 4, ' ') ||
                                                LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                '","Ictrim01","IteLocStor"' || ')', NEW.item);
                                    END IF;
                                END IF;
                            END IF;


                        ELSIF
                            (TG_OP = 'UPDATE' AND WBodegaconTransito AND OLD.status IS NULL) OR --RECEPCION DE TRANSFERENCIAS.
                            (TG_OP = 'INSERT' AND WBodegaconTransito AND COALESCE(NEW.cantidad_recibida, 0) <>
                                                                         0) THEN --LWO 2017-10-13. No se estaba considerando cuando es bodega de transito y la transacción ya vienen como recibida THEN

                            IF TG_OP = 'UPDATE' THEN
                                wCantidadRecibida = NEW.cantidad_recibida - OLD.cantidad_recibida;
                            ELSE
                                wCantidadRecibida = NEW.cantidad_recibida ;
                            END IF;

                            IF wCantidadRecibida <> 0 THEN
                                -- EXISTENCIAS POR ITEMS
                                UPDATE control_inventarios.items
                                SET existencia = existencia + wCantidadRecibida,
                                    transito   = CASE
                                                     WHEN TG_OP = 'INSERT' THEN transito
                                                     ELSE transito - wCantidadRecibida END
                                WHERE item = NEW.item;

                                IF New.es_psql THEN
                                    --LWO 2014/09/30 Graba en la interface
                                    wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                    wSqlGrabaInterface = 'REPLACE ionhand WITH ionhand+' ||
                                                         TRIM(TO_CHAR(wCantidadRecibida, '9999999.999')) || ',' ||
                                                         'transtra WITH transtra-' || CASE
                                                                                          WHEN TG_OP = 'INSERT'
                                                                                              THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                          ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END;
                                    INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo, actualizad,
                                                                   sql, proceso, directorio, tabla, buscar, codigo)
                                    VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA', 'NO',
                                            wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                                            '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                            NEW.item);
                                END IF;

                                --Grabar la fecha de la primera recepción en el primer almacén
                                UPDATE control_inventarios.items
                                SET primera_recepcion_punto_venta = NOW()
                                WHERE item = NEW.item
                                  AND primera_recepcion_punto_venta IS NULL;

                                IF found THEN
                                    IF New.es_psql THEN
                                        --LWO 2014/09/30 Graba en la interface
                                        wFechaGrabaVisual = '{^' || TO_CHAR(NOW(), 'YYYY/MM/DD') || '}';
                                        wSqlGrabaInterface = 'REPLACE primrecpv WITH ' || wFechaGrabaVisual;
                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA',
                                                'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'icitem01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || '","Icitem01","Item"' || ')',
                                                NEW.item);
                                    END IF;
                                END IF;

                                -- EXISTENCIAS POR BODEGA
                                UPDATE control_inventarios.bodegas
                                SET existencia                   = existencia + wCantidadRecibida,
                                    transito                     = CASE
                                                                       WHEN TG_OP = 'INSERT' THEN transito
                                                                       ELSE transito - wCantidadRecibida END,
                                    ultimo_ingreso_transferencia = NOW(),
                                    primera_recepcion            = CASE WHEN primera_recepcion IS NULL THEN NOW() ELSE primera_recepcion END
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item;

                                IF NOT FOUND THEN
                                    INSERT INTO control_inventarios.bodegas (item, bodega, creacion_usuario, existencia, transito)
                                    VALUES (NEW.item, NEW.bodega, NEW.creacion_usuario, wCantidadRecibida,
                                            CASE WHEN TG_OP = 'INSERT' THEN 0 ELSE wCantidadRecibida * -1 END);
                                ELSE
                                    IF New.es_psql THEN
                                        --LWO 2014/09/30 Graba en la interface
                                        wFechaGrabaVisual = '{^' || TO_CHAR(NOW(), 'YYYY/MM/DD') || '}';
                                        wSqlGrabaInterface = 'REPLACE lonhand WITH lonhand+' ||
                                                             TRIM(TO_CHAR(wCantidadRecibida, '9999999.999')) || ','
                                                                 || 'transtra WITH transtra-' || CASE
                                                                                                     WHEN TG_OP = 'INSERT'
                                                                                                         THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                                     ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END ||
                                                             ','
                                                                 || 'ltransingr WITH ' || wFechaGrabaVisual || ','
                                                                 || 'primerarec WITH IIF(EMPTY(primerarec),' ||
                                                             wFechaGrabaVisual || ' ,primerarec)';
                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA',
                                                'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                '","Iciloc01","Item1"' || ')', NEW.item);
                                    END IF;
                                END IF;

                                --Grabar la fecha que se transfiere en caso de los items que tengan existencia 0
                                UPDATE control_inventarios.bodegas
                                SET ultima_recepcion = NEW.fecha
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item
                                  AND existencia <= 0
                                  AND ultima_recepcion IS NULL;
                                IF found THEN
                                    IF New.es_psql THEN

                                        --LWO 2014/09/30 Graba en la interface
                                        wSqlGrabaInterface =
                                                'REPLACE lrecv WITH {^' || TO_CHAR(NOW(), 'YYYY/MM/DD') || '}';
                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA',
                                                'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciloc01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                '","Iciloc01","Item1"' || ')', NEW.item);
                                    END IF;
                                END IF;

                                -- EXISTENCIAS POR UBICACION
                                UPDATE control_inventarios.ubicaciones
                                SET existencia = existencia + wCantidadRecibida,
                                    transito   = CASE
                                                     WHEN TG_OP = 'INSERT' THEN transito
                                                     ELSE transito - wCantidadRecibida END
                                WHERE bodega = NEW.bodega
                                  AND item = NEW.item
                                  AND ubicacion = NEW.ubicacion;

                                IF NOT found THEN
                                    PERFORM *
                                    FROM control_inventarios.item_ubicacion_creacion_fnc(new.item, new.bodega,
                                                                                         new.ubicacion,
                                                                                         wCantidadRecibida,
                                                                                         new.creacion_usuario);
                                    UPDATE control_inventarios.ubicaciones
                                    SET transito = CASE
                                                       WHEN TG_OP = 'INSERT' THEN transito
                                                       ELSE transito - wCantidadRecibida END
                                    WHERE bodega = NEW.bodega
                                      AND item = NEW.item
                                      AND ubicacion = NEW.ubicacion;

                                    IF New.es_psql THEN
                                        --LWO 2014/09/30 Graba en la interface
                                        wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                        wSqlGrabaInterface = 'REPLACE transtra WITH transtra-' || CASE
                                                                                                      WHEN TG_OP = 'INSERT'
                                                                                                          THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                                      ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END;
                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA',
                                                'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                                    END IF;
                                ELSE
                                    IF New.es_psql THEN
                                        --LWO 2014/09/30 Graba en la interface
                                        wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                        wSqlGrabaInterface = 'REPLACE qonhand WITH qonhand+' ||
                                                             TRIM(TO_CHAR(wCantidadRecibida, '9999999.999')) || ','
                                                                 || 'transtra WITH transtra-' || CASE
                                                                                                     WHEN TG_OP = 'INSERT'
                                                                                                         THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                                     ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END;
                                        INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                       actualizad, sql, proceso, directorio, tabla,
                                                                       buscar, codigo)
                                        VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX', 'PTOVENTA',
                                                'NO', wSqlGrabaInterface, 'UPDATE', 'v:\sbtpro\icdata\ ', 'iciqty01',
                                                '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                RPAD(NEW.ubicacion, 4, ' ') || '","Iciqty01","Item5"' || ')', NEW.item);
                                    END IF; --New.es_psql THEN
                                END IF;
                                --not found then


                                --EXISTENCIAS POR TRIMESTRE.
                                --LWO 2017/12/21. A partir de esta fecha se controla los ubicaciones por trimestre.
                                IF NEW.anio_trimestre > 0 AND NEW.bodega IN ('999', '000', '001', '008', '023') THEN
                                    -- EXISTENCIAS POR TRIMESTRE
                                    UPDATE control_inventarios.ubicaciones_trimestre
                                    SET existencia = existencia + wCantidadRecibida,
                                        transito   = CASE
                                                         WHEN TG_OP = 'INSERT' THEN transito
                                                         ELSE transito - wCantidadRecibida END
                                    WHERE bodega = NEW.bodega
                                      AND item = NEW.item
                                      AND ubicacion = NEW.ubicacion
                                      AND anio_trimestre = NEW.anio_trimestre;

                                    IF NOT found THEN
                                        PERFORM *
                                        FROM control_inventarios.item_ubicacion_trimestre_creacion_fnc(new.item,
                                                                                                       new.bodega,
                                                                                                       new.ubicacion,
                                                                                                       NEW.anio_trimestre,
                                                                                                       wCantidadRecibida,
                                                                                                       new.creacion_usuario);
                                        UPDATE control_inventarios.ubicaciones_trimestre
                                        SET transito = CASE
                                                           WHEN TG_OP = 'INSERT' THEN transito
                                                           ELSE transito - wCantidadRecibida END
                                        WHERE bodega = NEW.bodega
                                          AND item = NEW.item
                                          AND ubicacion = NEW.ubicacion
                                          AND anio_trimestre = NEW.anio_trimestre;

                                        IF New.es_psql THEN
                                            --LWO 2014/09/30 Graba en la interface
                                            wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                            wSqlGrabaInterface = 'REPLACE transtra WITH transtra-' || CASE
                                                                                                          WHEN TG_OP = 'INSERT'
                                                                                                              THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                                          ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END;
                                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                           actualizad, sql, proceso, directorio, tabla,
                                                                           buscar, codigo)
                                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX',
                                                    'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                    'v:\sbtpro\icdata\ ', 'ictrim01',
                                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                    RPAD(NEW.ubicacion, 4, ' ') ||
                                                    LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                    '","Ictrim01","IteLocStor"' || ')', NEW.item);
                                        END IF;
                                    ELSE
                                        IF New.es_psql THEN
                                            --Graba en la interface
                                            wFechaGrabaVisual = '{^' || TO_CHAR(NEW.fecha, 'YYYY/MM/DD') || '}';
                                            wSqlGrabaInterface = 'REPLACE tonhand WITH tonhand+' ||
                                                                 TRIM(TO_CHAR(wCantidadRecibida, '9999999.999')) || ','
                                                                     || 'transtra WITH transtra-' || CASE
                                                                                                         WHEN TG_OP = 'INSERT'
                                                                                                             THEN TRIM(TO_CHAR(0, '9999999999.99999'))
                                                                                                         ELSE TRIM(TO_CHAR(wCantidadRecibida, '9999999999.99999')) END;
                                            INSERT INTO sistema.interface (fecha, hora, usuarios, generador, modulo,
                                                                           actualizad, sql, proceso, directorio, tabla,
                                                                           buscar, codigo)
                                            VALUES (CURRENT_DATE, LOCALTIME(0), NEW.creacion_usuario, 'LINUX',
                                                    'PTOVENTA', 'NO', wSqlGrabaInterface, 'UPDATE',
                                                    'v:\sbtpro\icdata\ ', 'ictrim01',
                                                    '=SEEK("' || RPAD(NEW.item, 15, ' ') || RPAD(NEW.bodega, 3, ' ') ||
                                                    RPAD(NEW.ubicacion, 4, ' ') ||
                                                    LPAD(NEW.anio_trimestre::TEXT, 10, ' ') ||
                                                    '","Ictrim01","IteLocStor"' || ')', NEW.item);
                                        END IF; --New.es_psql THEN
                                    END IF; --not found then
                                END IF;

                            END IF; --wCantidadRecibida<>0 THEN

                        END IF; --(TG_OP = 'UPDATE' AND WBodegaconTransito AND OLD.status IS NULL) OR   --RECEPCION DE TRANSFERENCIAS.
                    --(TG_OP = 'INSERT' AND WBodegaconTransito AND NEW.cantidad_recibida <> 0) THEN

                    END IF; --IF TG_OP = 'INSERT'
        --   OR (TG_OP = 'UPDATE' AND OLD.status='U' AND NEW.status IS NULL)
        --   OR (TG_OP = 'UPDATE' AND WBodegaconTransito AND OLD.status IS NULL  ) THEN   --Esta ultima condicion es para la recepcion de transferencias

            END CASE; --CASE NEW.tipo_movimiento

        DROP TABLE IF EXISTS es_vfp;
        RETURN NEW;
    END IF; --NEW.tipo_movimiento IN ('REUB CANT-','REUB CANT+','TRANSFER-','TRANSFER+') AND (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') then

    DROP TABLE IF EXISTS es_vfp;
    RETURN NEW;

END;
$function$
;
