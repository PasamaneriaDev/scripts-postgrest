select *
from ordenes_venta.pedidos_cabecera pc;


alter table ordenes_venta.pedidos_cabecera
add column aprobacion_cambio boolean default false;