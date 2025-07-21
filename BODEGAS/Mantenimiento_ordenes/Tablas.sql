ALTER TABLE trabajo_proceso.ordenes
    DROP COLUMN IF EXISTS orden_trazabilidad;

ALTER TABLE trabajo_proceso.ordenes
    ADD COLUMN orden_trazabilidad varchar(15) NULL;

-- trabajo_proceso.ordenes_type definition

DROP TYPE trabajo_proceso.ordenes_type;

CREATE TYPE trabajo_proceso.ordenes_type AS
(
    codigo_orden                   varchar,
    secuencia_codigo_barra         varchar,
    item                           varchar,
    cantidad_planificada           numeric,
    cantidad_fabricada             numeric,
    fecha_pedido                   date,
    fecha_emision                  date,
    fecha_inicio_planificacion     date,
    fecha_inicio_real              date,
    fecha_entrega_real             date,
    fecha_ultima_entrega           date,
    prioridad                      varchar,
    estado                         varchar,
    responsable                    varchar,
    tiene_requerimientos           bool,
    tiene_hoja_ruta                bool,
    problema                       varchar,
    fecha_ultimo_movimiento        date,
    desperdicio                    numeric,
    no_cerrar                      bool,
    cierre_automatico              bool,
    taller                         varchar,
    secuencia_programa             numeric,
    desgaste_buffer                numeric,
    centro                         varchar,
    fecha_operacion                date,
    operario                       varchar,
    numero_semana                  varchar,
    codigo_coleccion               varchar,
    manual                         bool,
    diseno1                        varchar,
    diseno2                        varchar,
    tiene_etiquetas                bool,
    orden_complemento              varchar,
    comentario                     varchar,
    operacion                      varchar,
    fecha_migrada                  date,
    migracion                      varchar,
    costo_materia_prima_unidad     numeric,
    costo_mano_obra_unidad         numeric,
    costo_gasto_fabricacion_unidad numeric,
    costo_materia_prima_total      numeric,
    costo_mano_obra_total          numeric,
    costo_gasto_fabricacion_total  numeric,
    antes_desgaste_buffer          numeric,
    fecha_entrega_planificada      date,
    anio_trimestre                 numeric,
    cantidad_segunda               numeric,
    estado_original                varchar,
    cantidad_planificada_orginal   numeric,
    modificador_op_tipo_id         int2,
    ultimo_lote_malla              bool,
    maquina                        varchar(15),
    codigo_orden_padre             varchar
);

