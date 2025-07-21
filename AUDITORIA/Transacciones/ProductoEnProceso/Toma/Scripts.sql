select *
from auditoria.papeletas_inventario
where numero_papeleta = '0000600007';


select *
from inventario_proceso.toma_producto_proceso_preliminar
where documento IN ('0000600007', '0000600008');

select *
from control_inventarios.ajustes
where documento IN ('0000600007', '0000600008');