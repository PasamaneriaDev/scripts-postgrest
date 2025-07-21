select numero_transaccion
from sistema.parametros_almacenes
where bodega = '001';

select cantidad*costo, *
from control_inventarios.transacciones
where fecha = current_date
and trim(transaccion) > trim('  51654348');

select *
from control_inventarios.distribucion
where transaccion in (select transaccion
from control_inventarios.transacciones
where fecha = current_date and trim(transaccion) > trim('  51654348'));


select max(secuencia)
from sistema.interface
where fecha = current_date::text;

select *
from sistema.interface
where secuencia > 812859681;


select *
from control_inventarios.ajustes
where fecha = current_date


/*****************************/
WITH fictitious_table AS (
    SELECT *
    FROM unnest(array[
        row(1, 'Item1'::text)::record,
        row(2, 'Item2'::text)::record,
        row(3, 'Item3'::text)::record
    ]) AS t(id int, name text)
)
SELECT ft.id, ft.name, LPAD(ti.numero::text, 10, ' ') AS transaccion
FROM fictitious_table ft
INNER JOIN lateral sistema.transaccion_inventario_numero_obtener(case when true then '001' end ) ti
ON true;

select *
from sistema.transaccion_inventario_numero_obtener('001')



/*************/

select *
from control_inventarios.items
where item = '28130055815405'


select *
from control_inventarios.items i
LEFT JOIN control_inventarios.precios p ON p.item = i.item AND p.tipo = 'PVP'
where p.tipo is null
and left(i.item, 1) = '1'