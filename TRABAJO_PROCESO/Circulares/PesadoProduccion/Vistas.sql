CREATE or replace VIEW trabajo_proceso.defectos_produccion_mallas_view
    (defectos_fabrica_id, origen, descripcion) AS
SELECT defectos_fabrica_id, origen, descripcion
FROM trabajo_proceso.defectos_fabrica
WHERE revision_circulares = true
ORDER BY origen, defectos_fabrica_id;



CREATE OR REPLACE VIEW trabajo_proceso.ordenes_rollos_paros_view
    (motivo, fecha_inicio, codigo_orden, numero_rollo) AS
SELECT motivo, fecha_inicio, codigo_orden, numero_rollo
FROM trabajo_proceso.ordenes_rollos_paros_mantenimiento pr
WHERE tipo = 'P';

select *
from trabajo_proceso.defectos_produccion_mallas_view