-- DROP TABLE trabajo_proceso.tintoreria_control_calidad
CREATE TABLE trabajo_proceso.tintoreria_control_calidad
(
    tintoreria_control_calidad_id serial4                  NOT NULL,
    codigo_orden                  varchar(15)              NOT NULL,
    observaciones                 varchar(500)             NULL,
    estado_lote                   varchar(50)              NULL,
    tono                          varchar(200)             NULL,
    gramaje                       numeric(10, 3) DEFAULT 0 NULL,
    ancho                         numeric(10, 3) DEFAULT 0 NULL,
    encogimiento_ancho            numeric(10, 3) DEFAULT 0 NULL,
    solidez_humedo                varchar(200)             NULL,
    solidez_frote                 varchar(200)             NULL,
    kilos_prueba                  numeric(10, 3) DEFAULT 0 NULL,
    defectos_observados           varchar(500)             NULL,
    creacion_fecha                timestamp      DEFAULT now() NULL,
    creacion_usuario              varchar(4)               NULL,
    encogimiento_largo            numeric(10, 3) DEFAULT 0 NULL,
    CONSTRAINT pk_secuencia_tintoreria_control_calidad PRIMARY KEY (tintoreria_control_calidad_id)
);


/*****************************/

SELECT *
FROM trabajo_proceso.tintoreria_control_calidad;

/*****************************/

-- drop table trabajo_proceso.tintoreria_pesos_balanza
CREATE TABLE trabajo_proceso.tintoreria_pesos_balanza
(
    tintoreria_pesos_balanza_id serial4                             NOT NULL,
    codigo_orden                varchar(15)                         NOT NULL,
    peso_bruto                  numeric(10, 3) DEFAULT 0,
    peso_neto                   numeric(10, 3) DEFAULT 0,
    ubicacion                   varchar(50)                         NULL,
    bodega                      varchar(3)                          NULL,
    peso_tara                   numeric(10, 3) DEFAULT 0,
    creacion_fecha              date           DEFAULT CURRENT_DATE NULL,
    creacion_hora               varchar        DEFAULT TO_CHAR(CURRENT_TIME::time, 'HH24:MI:SS') NULL,
    creacion_usuario            varchar(4)                          NULL,
    CONSTRAINT pk_secuencia_tintoreria_pesos_balanza PRIMARY KEY (tintoreria_pesos_balanza_id)
);


/******************************************/
DROP TABLE trabajo_proceso.tintoreria_ordenes_enviadas;
CREATE TABLE trabajo_proceso.tintoreria_ordenes_enviadas
(
    tintoreria_ordenes_enviadas_id serial4                  NOT NULL,
    codigo_orden                   varchar(15)              NOT NULL,
    cantidad                       numeric(10, 3) DEFAULT 0,
    bodega                         varchar(3)               NULL,
    ubicacion                      varchar(50)              NULL,
    cantidad_reubica               numeric(10, 3) DEFAULT 0 NULL,
    creacion_fecha                 timestamp      DEFAULT now() NULL,
    creacion_usuario               varchar(4)               NULL,
    CONSTRAINT pk_secuencia_tintoreria_ordenes_procesadas PRIMARY KEY (tintoreria_ordenes_procesadas_id)
);

ALTER TABLE trabajo_proceso.tintoreria_ordenes_enviadas
    RENAME tintoreria_ordenes_procesadas_id TO tintoreria_ordenes_enviadas_id;

ALTER TABLE trabajo_proceso.tintoreria_ordenes_enviadas
    ADD COLUMN rollos numeric(10, 3) DEFAULT 0 NULL;

ALTER TABLE trabajo_proceso.tintoreria_ordenes_enviadas
    ADD CONSTRAINT cantidad_reubica_menor_igual_cantidad CHECK (cantidad_reubica <= cantidad);

SELECT *
FROM trabajo_proceso.tintoreria_ordenes_enviadas;



