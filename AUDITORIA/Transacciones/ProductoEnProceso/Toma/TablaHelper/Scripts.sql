-- select auditoria.ajuste_toma_prod_proc_crea_tabla_resp('ajuste_toma_prod_proc_tmp');

select *
from inventario_proceso.toma_producto_proceso_preliminar;

select *
from control_inventarios.ajuste_toma_prod_proc_inserta_resp('ajuste_toma_prod_proc_tmp', '{
    "documento": "1234567890",
    "item": "ITEM001",
    "costo": 100.50,
    "costo_nuevo": 110.75,
    "orden": "ORD001",
    "cantidad": 50.25,
    "conos": 10,
    "tara": 5.5,
    "cajon": 2.0,
    "constante": 1.5,
    "muestra": "Sample data",
    "cantidad_ajuste": 0.75,
    "bodega": "B01",
    "ubicacion": "U001",
    "id_public": 1
  }');


select *
from control_inventarios.ajuste_toma_prod_proc_eliminar_resp_by_id('ajuste_toma_prod_proc_tmp', 1);


select sistema.get_secuencia_from_parametros('AUDITORIA', 'PAPELETAS_INVENTARIO_PROCESO')