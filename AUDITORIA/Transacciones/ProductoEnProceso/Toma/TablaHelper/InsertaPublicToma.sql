-- DROP FUNCTION control_inventarios.ajuste_toma_prod_proc_inserta_resp(tabla_nombre varchar, p_datajs text, o_id_public OUT integer)

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_prod_proc_inserta_resp(p_datajs text, o_id_public OUT integer)
    RETURNS integer
    LANGUAGE plpgsql
AS
$function$
BEGIN
    INSERT INTO inventario_proceso.toma_producto_proceso_preliminar(computador, usuario, item, costo, costo_nuevo,
                                                                    orden, cantidad,
                                                                    conos, tara, cajon, constante, muestra,
                                                                    cantidad_ajuste, bodega, ubicacion, documento)
    SELECT x.computador,
           x.usuario,
           x.item,
           x.costo,
           x.costo_nuevo,
           x.orden,
           x.cantidad,
           x.conos,
           x.tara,
           x.cajon,
           x.constante,
           x.muestra,
           x.cantidad_ajuste,
           x.bodega,
           x.ubicacion,
           LPAD(x.documento, 10, '0')
    FROM JSON_TO_RECORD(p_datajs::JSON) x (computador text, usuario text, documento TEXT, item TEXT, costo DECIMAL,
                                           costo_nuevo DECIMAL, orden TEXT, cantidad DECIMAL,
                                           conos INTEGER, tara DECIMAL, cajon DECIMAL,
                                           constante DECIMAL, muestra TEXT,
                                           cantidad_ajuste DECIMAL, bodega TEXT, ubicacion TEXT)
    RETURNING id_public
        INTO o_id_public;
END ;
$function$
;
