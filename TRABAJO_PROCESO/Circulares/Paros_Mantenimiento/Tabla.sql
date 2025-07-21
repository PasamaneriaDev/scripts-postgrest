-- drop table trabajo_proceso.ordenes_rollos_paros_mantenimiento;

CREATE TABLE trabajo_proceso.ordenes_rollos_paros_mantenimiento
(
    id_ordenes_rollos_paros_mantenimiento SERIAL,
    codigo_orden                          VARCHAR(15),                                  --Paro
    numero_rollo                          VARCHAR(3),                                   --Paro
    tipo                                  VARCHAR(1)                          NOT NULL, --
    motivo                                VARCHAR(255)                        NOT NULL, --
    fecha_inicio                          timestamp DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Aut
    fecha_fin                             timestamp,                                    -- Aut
    maquina                               VARCHAR(50),                                  --Mant
    creacion_usuario                      VARCHAR(50),
    CONSTRAINT ordenes_rollos_paros_mantenimiento_pk PRIMARY KEY (id_ordenes_rollos_paros_mantenimiento),
    CONSTRAINT ordenes_rollos_paros_mantenimiento_codigo_orden_numero_rollo_fk
        FOREIGN KEY (codigo_orden, numero_rollo)
            REFERENCES trabajo_proceso.ordenes_rollos_detalle (codigo_orden, numero_rollo)
);

