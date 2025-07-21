ALTER TABLE puntos_venta.incidencias
    RENAME COLUMN recepcion_usuario TO autorizacion_usuario;

ALTER TABLE puntos_venta.incidencias
    RENAME COLUMN recepcion_fecha TO autorizacion_fecha;

ALTER TABLE puntos_venta.incidencias
    ADD COLUMN ejecucion_usuario       varchar(4),
    ADD COLUMN ejecucion_fecha         timestamp,
    ADD COLUMN noejecutado_usuario     varchar(4),
    ADD COLUMN noejecutado_fecha       timestamp,
    ADD COLUMN observacion_noejecutado varchar(400);


CREATE OR REPLACE FUNCTION puntos_venta.incidencias_actualizar_estado()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.finalizacion_fecha IS NOT NULL THEN
        NEW.estado := 'COMPLETO';
    ELSIF NEW.noejecutado_fecha IS NOT NULL THEN
        NEW.estado := 'NO EJECUTADO';
    ELSIF NEW.noautorizado_fecha IS NOT NULL THEN
        NEW.estado := 'NO AUTORIZADO';
    ELSIF NEW.ejecucion_fecha IS NOT NULL THEN
        NEW.estado := 'EN EJECUCION';
    ELSIF NEW.autorizacion_fecha IS NOT NULL THEN
        NEW.estado := 'AUTORIZADO';
    ELSE
        NEW.estado := 'EN TRAMITE';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


ALTER TABLE sistema.usuarios
ADD COLUMN recibe_incidencias BOOLEAN;