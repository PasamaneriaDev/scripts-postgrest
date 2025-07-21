DROP TABLE auditoria.papeletas_inventario;


CREATE TABLE auditoria.papeletas_inventario (
	numero_papeleta varchar(10) DEFAULT lpad(sistema.get_secuencia_from_parametros('AUDITORIA'::character varying, 'PAPELETAS_INVENTARIO_PROCESO'::character varying)::character varying::text, 10, '0'::text) NOT NULL,
	fecha date NOT NULL,
	bodega varchar(3) NOT NULL,
	ubicacion varchar(4) NOT NULL,
	creacion_usuario varchar(4) NULL,
	creacion_fecha timestamp DEFAULT now() NULL,
	bloqueado_por varchar(4) DEFAULT ''::character varying NULL,
	bloqueado_timestamp timestamp NULL,
	CONSTRAINT pk_papeletas PRIMARY KEY (numero_papeleta)
);


-- Crear la función del trigger
CREATE OR REPLACE FUNCTION actualizar_bloqueado_timestamp()
    RETURNS TRIGGER AS
$$
BEGIN
    IF COALESCE(NEW.bloqueado_por, '') <> '' THEN
        NEW.bloqueado_timestamp = CURRENT_TIMESTAMP;
    ELSE
        NEW.bloqueado_timestamp = NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Crear el trigger
CREATE TRIGGER trg_actualizar_bloqueado_timestamp
    BEFORE INSERT OR UPDATE
    ON auditoria.papeletas_inventario
    FOR EACH ROW
EXECUTE FUNCTION actualizar_bloqueado_timestamp();


select *
from sistema.parametros p
where modulo_id = 'AUDITORIA'
and codigo = 'PAPELETAS_INVENTARIO_PROCESO';

insert into sistema.parametros (modulo_id, codigo, descripcion, numero)
values ('AUDITORIA', 'PAPELETAS_INVENTARIO_PROCESO', 'Papeletas de inventario de proceso', 600000)