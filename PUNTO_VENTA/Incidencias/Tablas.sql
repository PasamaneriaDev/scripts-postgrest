-- drop table puntos_venta.incidencias
CREATE TABLE puntos_venta.incidencias
(
    numero_incidencia        serial4      NOT NULL,
    centro_costo             varchar(3)   NOT NULL,
    grupo                    varchar(100) NOT NULL,
    observacion              varchar(400) NOT NULL,
    estado                   VARCHAR(20) NOT NULL DEFAULT 'EN TRAMITE',

    creacion_usuario         varchar(4)   NOT NULL,
    creacion_fecha           timestamp    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    recepcion_usuario        varchar(4)   NULL,
    recepcion_fecha          timestamp    NULL,

    finalizacion_usuario     varchar(4)   NULL,
    finalizacion_fecha       timestamp    NULL,

    noautorizado_usuario     varchar(4)   NULL,
    noautorizado_fecha       timestamp    NULL,
    observacion_noautorizado varchar(400) NULL,

    CONSTRAINT pk_secuencia_numero_incidencias
        PRIMARY KEY (numero_incidencia)
);

INSERT INTO sistema.parametros (modulo_id, codigo, descripcion, alfa, numero, fecha, conversion_dolar,
                                fecha_ultima_actualizacion, fecha_migrada, migracion, numero_ord_mp, interface_envia)
VALUES ('SISTEMA', 'CORREO_AUTO_INCIDEN_REQUERIM',
        'Correo al que se envia automaticamente cuando se registra incidencias o requerimientos de los Almacenes',
        'janeth.rodas@pasa.ec,lourdes.rugel@pasa.ec', 0, NULL, FALSE,
        CURRENT_DATE, NULL, 'NO', NULL, FALSE);





CREATE TRIGGER trg_actualizar_estado
BEFORE INSERT OR UPDATE ON puntos_venta.incidencias
FOR EACH ROW
EXECUTE FUNCTION puntos_venta.incidencias_actualizar_estado();




INSERT INTO sistema.parametros (modulo_id, codigo, descripcion, alfa, numero, fecha, conversion_dolar,
                                fecha_ultima_actualizacion, fecha_migrada, migracion, numero_ord_mp, interface_envia)
VALUES ('CRM', 'CORREO_AUTO_ENCARGADO_CALIDAD',
        'Correo del Encargado de Calidad al que se envia automaticamente notificaciones',
        'nube.sanango@pasa.ec', 0.000000, NULL, FALSE, '2024-10-30', NULL, 'NO', NULL, FALSE);




-- MENUS
-- AlmacenesIncidentes
-- AlmacenesRequerimientos