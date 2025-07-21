-- drop VIEW trabajo_proceso.ubicaciones_mallas_tinturadas_view

CREATE OR REPLACE VIEW trabajo_proceso.ubicaciones_mallas_tinturadas_view AS
SELECT iu.bodega, ib.descripcion, iu.ubicacion
FROM control_inventarios.id_ubicaciones iu
JOIN control_inventarios.id_bodegas ib on iu.bodega = ib.bodega
WHERE (iu.bodega = 'GT7' AND iu.ubicacion = 'GV03')
   OR (iu.bodega = 'BT7' AND iu.ubicacion = 'BTIN')
   ;


SELECT *
FROM control_inventarios.id_bodegas iu
where iu.bodega like 'BT%'


select left('Bodega De Confecciones- Mallas Tinturadas',) as prueba