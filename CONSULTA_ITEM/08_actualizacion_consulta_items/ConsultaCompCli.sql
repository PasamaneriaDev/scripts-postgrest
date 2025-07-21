-- DROP FUNCTION control_inventarios.item_consulta_compromiso_cliente(p_item character varying)

CREATE OR REPLACE FUNCTION control_inventarios.item_consulta_compromiso_cliente(p_item character varying)
    RETURNS TABLE
            (
                bodega                character varying,
                cliente_ubic          character varying,
                cliente               character varying,
                numero_pedido         character varying,
                fecha_pedido          date,
                fecha_entrega         date,
                item                  character varying,
                cantidad_pendiente    numeric,
                cantidad_despacho     numeric,
                es_dudoso             character varying,
                status                character varying,
                verifica_vencimiento  text,
                tiene_vencimiento     boolean,
                protestado            boolean,
                nombre_cliente        character varying,
                vendedor              character varying,
                fecha_original_pedido date,
                fecha_ultimo_despacho date,
                dudoso                boolean,
                estado                character varying,
                tipo_pedido           character varying,
                creacion_fecha        date,
                descripcion           character varying,
                cantidad_original     numeric,
                fecha_eliminacion     date
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    Lv_Paso             character VARYING;
    registro            RECORD;
    Ln_diasentrega      numeric(2, 0);
    Ln_montovencimiento numeric(2, 0);
    Ln_disponible       numeric(10, 3) := 0;
    Ln_disponible_c     numeric(10, 3) := 0;
BEGIN
    SELECT numero INTO Ln_diasentrega FROM sistema.parametros WHERE codigo = 'DIAS_ENTREG_PED';
    SELECT numero INTO Ln_montovencimiento FROM sistema.parametros WHERE codigo = 'MONTO_VENCIMIEN';

    Lv_Paso = 'Paso 1. Obtiene total de existencias por item';
    --Totaliza las existencias por bodega. Y para los clientes especiales (MEGAMAXI, ETAFASHION) totaliza por
    --cliente considerando únicamente las ubicaciones especiales de estos clientes.
    --create temp table exisubic
    DROP TABLE IF EXISTS _temp_exist_ubic;
    CREATE TEMP TABLE _temp_exist_ubic
    AS
    SELECT LPAD(COALESCE(c.cliente, ''), 6, ' ') cliente, u.bodega, SUM(u.existencia) existencia, 0 AS disponible
    FROM control_inventarios.ubicaciones u
             LEFT JOIN ordenes_venta.clientes_ubicaciones c ON u.bodega = c.bodega AND u.ubicacion = c.ubicacion
    WHERE u.item = p_item
      AND (u.existencia - u.comprometido_despacho) > 0
    GROUP BY c.cliente, u.bodega;

    Lv_Paso = 'Paso 1.1. Obtiene total de comprometido para despacho';
    DROP TABLE IF EXISTS _temp_comprometido;
    CREATE TEMP TABLE _temp_comprometido
    AS
    SELECT t1.cliente, t1.bodega, SUM(t1.cantidad_pendiente) comprometido, 0 AS disponible
    FROM ordenes_venta.orden_despacho t1
    WHERE t1.item = p_item
      AND t1.cantidad_pendiente > 0
      AND COALESCE(t1.estado, '') = ''
    GROUP BY t1.cliente, t1.bodega;


    Lv_Paso = 'Paso 2. Obtiene pedidos pendientes';
    --Obtiene los pedidos pendientes: No asigna el disponible para los clientes que tienen: vencimientos, clientes dudosos,
    --clientes anulados, clientes que tienen cheques protestados.
    --create temp table pedipend
    DROP TABLE IF EXISTS _temp_pedidos_pendientes;
    CREATE TEMP TABLE _temp_pedidos_pendientes
    AS
    SELECT d.bodega,
           '      '::VARCHAR                                                     AS cliente_ubic,
           d.cliente,
           d.numero_pedido,
           d.fecha_pedido,          -- fecped
           cab.fecha_entrega,
           d.item,
           d.cantidad_pendiente,
           0::numeric                                                            AS cantidad_despacho,
           c.es_dudoso,
           c.status,
           LEFT(C.banderas, 1)                                                   AS verifica_vencimiento,
           cuentas_cobrar.clientes_estado_vencimiento(d.cliente) = 'VENCIMIENTO' AS tiene_vencimiento,
           cuentas_cobrar.clientes_estado_vencimiento(d.cliente) = 'PROTESTADO'  AS protestado,
           c.nombre                                                              AS nombre_cliente,
           d.vendedor,
           d.fecha_original_pedido, --ordate
           d.fecha_ultimo_despacho, --fecent
           cuentas_cobrar.clientes_estado_vencimiento(d.cliente) = 'DUDOSO'      AS dudoso,
           d.estado,
           d.tipo_pedido,
           d.creacion_fecha,
           d.descripcion,
           d.cantidad_original,
           d.fecha_eliminacion
    FROM ordenes_venta.pedidos_detalle d
             INNER JOIN cuentas_cobrar.clientes c ON d.cliente = c.codigo
             INNER JOIN ordenes_venta.pedidos_cabecera cab ON d.numero_pedido = cab.numero_pedido
    WHERE d.item = p_item
      AND NOT COALESCE(d.estado, '') IN ('C', 'V', '-', 'X')
      AND COALESCE(d.tipo_pedido, '') <> 'B'
      AND d.cantidad_pendiente > 0
      AND COALESCE(c.status, '') = ''
      AND COALESCE(c.es_dudoso, '') <> 'DU';

    Lv_Paso = 'Paso 4. Coloca código de clientes que tienen ubicaciones especiales';
    --Por ejemplo: MEGAMAXI, ETAFASHION, se despachan unicamente de las ubicaciones que les corresponden.
    UPDATE _temp_pedidos_pendientes p
    SET cliente_ubic = e.cliente
    FROM _temp_exist_ubic e
    WHERE p.cliente = e.cliente;

    Lv_Paso = 'Paso 5. --Calcula disponible de pedidos que no tienen vencimientos';
    FOR registro IN (SELECT p.*
                     FROM _temp_pedidos_pendientes p
                     WHERE p.verifica_vencimiento <> 'V'
                        OR (p.verifica_vencimiento = 'V' AND p.tiene_vencimiento = FALSE AND p.protestado = FALSE)
                     ORDER BY p.bodega, p.fecha_pedido, p.numero_pedido)
        LOOP

            UPDATE _temp_exist_ubic e
            SET disponible = CASE
                                 WHEN existencia > registro.cantidad_pendiente::NUMERIC THEN registro.cantidad_pendiente::NUMERIC
                                 ELSE existencia END,
                existencia = CASE
                                 WHEN existencia > registro.cantidad_pendiente::NUMERIC
                                     THEN existencia - registro.cantidad_pendiente::NUMERIC
                                 ELSE 0 END
            WHERE e.cliente = registro.cliente_ubic::VARCHAR
              AND e.bodega = registro.bodega::VARCHAR
            RETURNING e.disponible INTO Ln_disponible;

            Ln_disponible = COALESCE(Ln_disponible, 0);

            registro.cantidad_pendiente = registro.cantidad_pendiente - Ln_disponible;

            UPDATE _temp_comprometido a
            SET disponible   = CASE
                                   WHEN comprometido > registro.cantidad_pendiente::NUMERIC
                                       THEN registro.cantidad_pendiente::NUMERIC
                                   ELSE comprometido END,
                comprometido = CASE
                                   WHEN comprometido > registro.cantidad_pendiente::NUMERIC
                                       THEN comprometido - registro.cantidad_pendiente::NUMERIC
                                   ELSE 0 END
            WHERE a.cliente = registro.cliente::VARCHAR
              AND a.bodega = registro.bodega::VARCHAR
            RETURNING a.disponible INTO Ln_disponible_c;

            Ln_disponible = Ln_disponible + COALESCE(Ln_disponible_c, 0);


            UPDATE _temp_pedidos_pendientes p
            SET cantidad_despacho = Ln_disponible
            WHERE p.numero_pedido = registro.numero_pedido::VARCHAR
              AND p.item = registro.item::VARCHAR;

        END LOOP;

    RETURN QUERY
        SELECT p.bodega,
               p.cliente_ubic,
               p.cliente,
               p.numero_pedido,
               p.fecha_pedido,
               p.fecha_entrega,
               p.item,
               ROUND(p.cantidad_pendiente, 3) AS cantidad_pendiente,
               ROUND(p.cantidad_despacho, 3)  AS cantidad_despacho,
               p.es_dudoso,
               p.status,
               p.verifica_vencimiento,
               p.tiene_vencimiento,
               p.protestado,
               p.nombre_cliente,
               p.vendedor,
               p.fecha_original_pedido,
               p.fecha_ultimo_despacho,
               p.dudoso,
               p.estado,
               p.tipo_pedido,
               p.creacion_fecha,
               p.descripcion,
               p.cantidad_original,
               p.fecha_eliminacion
        FROM _temp_pedidos_pendientes p
        ORDER BY p.bodega, p.fecha_pedido, p.numero_pedido;
END ;
$function$
;
