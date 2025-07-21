BEGIN;
SELECT catalogos.productos_merge_subir_txt(
               '[{"catalogo":"023","item":"1BBN2066343041","articulo":"1BBN","detalle":"2","talla":"06","color":"634307","empaque":"1","descripcion_articulo":"BODY MANGA CORTA","color_comercial":"CELESTE CLARO","precio_base":"9.12","precio_catalogo":"10.49"},{"catalogo":"023","item":"1BBN2066740231","articulo":"1BBN","detalle":"2","talla":"06","color":"674023","empaque":"1","descripcion_articulo":"BODY MANGA CORTA","color_comercial":"CELESTE OSCUR","precio_base":"9.12","precio_catalogo":"10.49"}]',
               '3191');

rollback;

SELECT *
FROM sistema.interface
WHERE usuarios = '3191'
  AND fecha::date = CURRENT_DATE;


select *
from catalogos.color_comercial cc
where codigo_color = '634304'
and cc.codigo_catalogo = '023';

select *
from lista_materiales.colores c
where c.codigo = right('634307', 5)


select *
from catalogos.productos
where codigo_catalogo = '023';


select *
from catalogos.productos
where codigo_catalogo = '024';


select *
from catalogos.productos
where codigo_catalogo = '025';

select *
from control_inventarios.items
where left(item, 4) = '1BBN'


select '3aaa'ILIKE '3%'