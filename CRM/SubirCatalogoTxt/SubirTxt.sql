-- DROP FUNCTION control_inventarios.ajuste_cantidad_desde_txt(varchar, varchar);

CREATE OR REPLACE FUNCTION catalogos.productos_merge_subir_txt(p_datajs character varying, p_usuario character varying)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    DROP TABLE IF EXISTS items_catalogo_tmp;

    CREATE TEMP TABLE items_catalogo_tmp
    AS
    SELECT a.catalogo,
           a.item,
           a.articulo,
           CASE
               WHEN a.empaque ILIKE '3%' THEN '5'
               WHEN a.empaque ILIKE '2%' THEN 'D'
               ELSE
                   a.detalle END AS detalle,
           a.talla,
           a.color,
           a.empaque,
           a.descripcion_articulo,
           TRIM(color_comercial) AS color_comercial,
           a.precio_base,
           a.precio_catalogo
    FROM JSON_TO_RECORDSET(p_datajs::json) a (catalogo varchar, linea VARCHAR, familia varchar, item varchar,
                                              articulo varchar, detalle varchar, talla varchar, color varchar,
                                              empaque varchar, descripcion_articulo varchar,
                                              color_comercial varchar, codigo_rotacion varchar,
                                              precio_base decimal, precio_catalogo decimal);

    WITH t AS (
        UPDATE catalogos.productos AS p
            SET precio_base = a.precio_base::numeric(10, 3),
                precio_catalogo = a.precio_catalogo::numeric(10, 3),
                descripcion_articulo = a.descripcion_articulo::numeric(10, 3)
            FROM items_catalogo_tmp a
            WHERE p.codigo_catalogo = a.catalogo
                AND p.item = a.item
                AND p.articulo = a.articulo
                AND p.color = a.color
                AND p.color_comercial = a.color_comercial
                AND p.talla = a.talla
            RETURNING p.codigo_catalogo, p.item, p.articulo, p.detalle, p.talla, p.color, p.empaque,
                p.descripcion_articulo, p.color_comercial, p.precio_base, p.precio_catalogo)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'CRM'
         , 'UPDATE1'
         , 'item_catalogo'
         , p_usuario
         , 'v:\sbtpro\sodata\ '
         , ''
         , FORMAT('UPDATE v:\sbtpro\sodata\item_catalogo ' ||
                  'Set precio = %s, precio_iva = %s ' ||
                  'Where cod_catalo = [%s] ' ||
                  '  and item = [%s] ' ||
                  '  and articulo = [%s] ' ||
                  '  and color = [%s] ' ||
                  '  and color_come = [%s] ' ||
                  '  and talla = [%s] ',
                  s.precio_base, s.precio_catalogo, s.codigo_catalogo, RPAD(s.item, 15, ' '), s.articulo, s.color,
                  s.color_comercial, s.talla)
    FROM t AS s
    WHERE _interface_activo;

    WITH t AS (
        INSERT INTO catalogos.productos AS p
            (codigo_catalogo, item, articulo, detalle, talla, color, empaque, descripcion_articulo, color_comercial,
             precio_base, precio_catalogo)
            SELECT a.catalogo,
                   a.item,
                   a.articulo,
                   a.detalle,
                   a.talla,
                   a.color,
                   a.empaque,
                   a.descripcion_articulo,
                   a.color_comercial,
                   a.precio_base,
                   a.precio_catalogo
            FROM items_catalogo_tmp a
            ON CONFLICT (codigo_catalogo, item, articulo, color, color_comercial, talla) DO NOTHING
            RETURNING p.codigo_catalogo, p.item, p.articulo, p.detalle, p.talla, p.color, p.empaque,
                p.descripcion_articulo, p.color_comercial, p.precio_base, p.precio_catalogo)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'CRM'
         , 'INSERT1'
         , 'item_catalogo'
         , p_usuario
         , 'v:\sbtpro\sodata\ '
         , ''
         , FORMAT('INSERT INTO v:\sbtpro\sodata\item_catalogo ' ||
                  '(cod_catalo, item, articulo, detalle, talla, color, ' ||
                  ' empaque, descripcio, color_come, precio, precio_iva) ' ||
                  'VALUES ([%s], [%s], [%s], [%s], [%s], [%s], ' ||
                  '        [%s], [%s], [%s], %s, %s)',
                  s.codigo_catalogo, RPAD(s.item, 15, ' '), s.articulo, s.detalle, s.talla, s.color,
                  s.empaque, s.descripcion_articulo, s.color_comercial, s.precio_base, s.precio_catalogo)
    FROM t AS s
    WHERE _interface_activo;

    INSERT INTO catalogos.color_comercial AS p
        (codigo_color, color_comercial, codigo_catalogo)
    SELECT a.color,
           a.color_comercial,
           a.catalogo
    FROM items_catalogo_tmp a
             LEFT JOIN catalogos.color_comercial cc
                       ON a.catalogo = cc.codigo_catalogo
                           AND a.color_comercial = cc.color_comercial
                           AND a.color = cc.codigo_color
    WHERE cc.codigo_color IS NULL;

    WITH t AS (
        INSERT INTO lista_materiales.colores AS p
            (codigo, descripcion, tipo, fecha_ultimo_movimiento, minimo_produccion, color_fondo, foto, pantone,
             orden_cintas, fecha_migrada, migracion)
            SELECT RIGHT(a.color, 5),
                   a.color_comercial,
                   '',
                   CURRENT_DATE,
                   '0.00',
                   '',
                   '',
                   NULL,
                   NULL,
                   NULL,
                   'NO'
            FROM items_catalogo_tmp a
            ON CONFLICT (codigo) DO NOTHING
            RETURNING p.codigo, p.descripcion, p.tipo, p.fecha_ultimo_movimiento,
                p.minimo_produccion, p.color_fondo, p.foto, p.pantone, p.orden_cintas, p.fecha_migrada, p.migracion)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'CRM'
         , 'INSERT1'
         , 'COLORITE'
         , p_usuario
         , 'F:\home\spp\LISTAMAT\DATA\ '
         , ''
         , FORMAT('INSERT INTO F:\home\spp\LISTAMAT\DATA\COLORITE ' ||
                  '(codigo, descripcio, tipo, FECULTACT, MINIMOPROD, ' ||
                  ' BACKCOLOR, FOTOCOLOR, PANTONECOL, ORDENCINTA) ' ||
                  'VALUES ([%s], [%s], [%s], {^%s}, %s, ' ||
                  '        [%s], [%s], [%s], [%s])',
                  s.codigo, s.descripcion, s.tipo, TO_CHAR(s.fecha_ultimo_movimiento, 'YYYY-MM-DD'),
                  s.minimo_produccion,
                  s.color_fondo, s.foto, s.pantone, s.orden_cintas)
    FROM t AS s
    WHERE _interface_activo;

END ;
$function$
;
