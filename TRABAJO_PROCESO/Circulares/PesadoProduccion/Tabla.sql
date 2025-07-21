CREATE TABLE trabajo_proceso.ordenes_rollos_defectos
(
    id_ordenes_rollos_defectos SERIAL,
    codigo_orden               VARCHAR(15) NOT NULL,
    numero_rollo               VARCHAR(3)  NOT NULL,
    defectos_fabrica_id        VARCHAR(10) NOT NULL,
    creacion_usuario           VARCHAR(50),
    creacion_fecha             date DEFAULT CURRENT_DATE,
    CONSTRAINT ordenes_rollos_defectos_pk PRIMARY KEY (id_ordenes_rollos_defectos),
    CONSTRAINT ordenes_rollos_defectos_codigo_orden_numero_rollo_fk
        FOREIGN KEY (codigo_orden, numero_rollo)
            REFERENCES trabajo_proceso.ordenes_rollos_detalle (codigo_orden, numero_rollo)
)
;

ALTER TABLE trabajo_proceso.defectos_fabrica
    ADD COLUMN revision_circulares boolean DEFAULT FALSE;


SELECT *
FROM trabajo_proceso.tintoreria_pesos_balanza;


ALTER TABLE trabajo_proceso.tintoreria_pesos_balanza
    ADD COLUMN codigo_orden_crudo varchar(15) DEFAULT NULL,
    ADD COLUMN numero_rollo       varchar(3)  DEFAULT NULL;
