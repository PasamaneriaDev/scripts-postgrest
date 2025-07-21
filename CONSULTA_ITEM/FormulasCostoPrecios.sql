-- DROP FUNCTION control_inventarios.item_consulta_rutas_con_proceso(p_item character varying,p_orden character varying,p_centro character varying,p_operacion character varying)

CREATE OR REPLACE FUNCTION control_inventarios.item_consulta_formulas_costos_precios(p_item character varying)
    RETURNS table
            (
                precio_distribuidor varchar,
                precio_mayorista    varchar,
                precio_mercantil    varchar,
                precio_cadena       varchar,
                precio_exportacion  varchar,
                precio_oferta       varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_precio_distribuidor varchar;
    v_precio_mayorista    varchar;
    v_precio_mercantil    varchar;
    v_precio_cadena       varchar;
    v_precio_exportacion  varchar;
    v_precio_oferta       varchar;
    v_pvp_base            numeric;
    v_pvp_precio          numeric;
BEGIN
    -- Se usa en el panel de Costos y Precios en consulta de Items
    SELECT p.precio, p.pvp_base
    INTO v_pvp_precio, v_pvp_base
    FROM control_inventarios.precios p
    WHERE p.item = p_item
      AND p.tipo = 'PVP';

    -- PRECIO DISTRIBUIDOR
    IF LEFT(p_item, 1) IN ('1', '5') THEN
        IF (LEFT(p_item, 2) NOT IN ('1W', '1Y', '1X', '1V') AND LEFT(p_item, 1) != '5') OR
           (LEFT(p_item, 1) = '5' AND SUBSTR(p_item, 14, 1) = '0') THEN
            IF COALESCE(v_pvp_base, 0) > 0 THEN
                v_precio_distribuidor =
                        'PvpBase*Factor Distribuidor=' || v_pvp_base || '*0,4914.El precio se redondea a dos decimales';
            ELSE
                v_precio_distribuidor = 'PVP*Factor Distribuidor=' || COALESCE(v_pvp_precio, 0)::varchar ||
                                        '*0,4914.El precio se redondea a dos decimales';
            END IF;
        END IF;
    END IF;

    -- PRECIO MAYORISTA
    IF LEFT(p_item, 1) IN ('1', '5') THEN -- CONFECCIONES Y MEDIAS
        IF (LEFT(p_item, 2) NOT IN ('1W', '1Y', '1X', '1V') AND LEFT(p_item, 1) != '5') OR
           (LEFT(p_item, 1) = '5' AND SUBSTR(p_item, 14, 1) = '0') THEN
            IF COALESCE(v_pvp_base, 0) > 0 THEN
                v_precio_mayorista =
                        'PvpBase*Factor Mayorista=' || v_pvp_base || '*0,681818.El precio se redondea a dos decimales';
            ELSE
                v_precio_mayorista = 'PVP*Factor Mayorista=' || COALESCE(v_pvp_precio, 0)::varchar ||
                                     '*0,681818.El precio se redondea a dos decimales';
            END IF;
        END IF;
    ELSEIF LEFT(p_item, 1) IN ('2', '3', '4', '6') THEN -- ENCAJES-TELARES-TRENZADORAS-HILOS DE SEDA
        IF LEFT(p_item, 1) = '2' AND SUBSTR(p_item, 14, 1) IN ('4', '0') THEN
            v_precio_mayorista = 'PVP*0.75. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '3' AND SUBSTR(p_item, 14, 1) IN ('K', 'V', '0') THEN
            v_precio_mayorista = 'PvpDis*0.75. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '6' AND SUBSTR(p_item, 14, 1) IN ('0', '4') THEN
            v_precio_mayorista = 'PVP*0.75. El precio se redondea a dos decimales';
        END IF;
    END IF;

    -- PRECIO MERCANTIL
    IF LEFT(p_item, 1) IN ('1', '5') THEN -- CONFECCIONES Y MEDIAS
        IF (LEFT(p_item, 2) NOT IN ('1W', '1Y', '1X', '1V') AND LEFT(p_item, 1) != '5') OR
           (LEFT(p_item, 1) = '5' AND SUBSTR(p_item, 14, 1) = '0') THEN
            IF COALESCE(v_pvp_base, 0) > 0 THEN
                v_precio_mercantil =
                        'PvpBase*Factor Mercantil=' || v_pvp_base || '*0,645455.El precio se redondea a dos decimales';
            ELSE
                v_precio_mercantil = 'PVP*Factor Mercantil=' || COALESCE(v_pvp_precio, 0)::varchar ||
                                     '*0,645455.El precio se redondea a dos decimales';
            END IF;
        END IF;

    ELSEIF LEFT(p_item, 1) IN ('6', '2', '3', '4') THEN -- ENCAJES-TELARES-TRENZADORAS-HILOS DE SEDA
        IF LEFT(p_item, 1) = '2' AND SUBSTR(p_item, 14, 1) IN ('4', '0') THEN
            v_precio_mercantil = 'PVP*0.71. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '3' AND SUBSTR(p_item, 14, 1) IN ('K', 'V', '0') THEN
            v_precio_mercantil = 'PvpDis*0.71. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '6' AND SUBSTR(p_item, 14, 1) IN ('0', '4') THEN
            v_precio_mercantil = 'PVP*0.71. El precio se redondea a dos decimales';
        END IF;
    END IF;

    -- PRECIO CADENA
    IF LEFT(p_item, 1) IN ('1', '5') THEN -- CONFECCIONES Y MEDIAS
        IF (LEFT(p_item, 2) NOT IN ('1W', '1Y', '1X', '1V') AND LEFT(p_item, 1) != '5') OR
           (LEFT(p_item, 1) = '5' AND SUBSTR(p_item, 14, 1) = '0') THEN
            IF COALESCE(v_pvp_base, 0) > 0 THEN
                v_precio_cadena =
                        'PvpBase*Factor Cadena=' || v_pvp_base || '*0,6.El precio se redondea a dos decimales';
            ELSE
                v_precio_cadena = 'PVP*Factor Cadena=' || COALESCE(v_pvp_precio, 0)::varchar ||
                                  '*0,6.El precio se redondea a dos decimales';
            END IF;
        END IF;
    ELSEIF LEFT(p_item, 1) IN ('6', '2', '3', '4') THEN -- ENCAJES-TELARES-TRENZADORAS-HILOS DE SEDA
        IF LEFT(p_item, 1) = '2' AND SUBSTR(p_item, 14, 1) IN ('4', '0') THEN
            v_precio_cadena = 'PVP*0.66. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '3' AND SUBSTR(p_item, 14, 1) IN ('K', 'V', '0') THEN
            v_precio_cadena = 'PVP*0.66. El precio se redondea a dos decimales';
        ELSEIF LEFT(p_item, 1) = '6' AND SUBSTR(p_item, 14, 1) IN ('0', '4') THEN
            v_precio_cadena = 'PVP*1.85. El precio se redondea a dos decimales';
        END IF;
    END IF;

    -- PRECIO EXPORTACION
    IF LEFT(p_item, 1) IN ('6', '2', '3', '4') THEN -- ENCAJES-TELARES-TRENZADORAS-HILOS DE SEDA
        IF (LEFT(p_item, 1) = '2' AND SUBSTR(p_item, 14, 1) IN ('4', '0')) THEN
            v_precio_exportacion = 'PVP DISTRIBUIDOR*1.85. El precio se redondea a dos decimales';
        ELSEIF (LEFT(p_item, 1) = '3' AND SUBSTR(p_item, 14, 1) IN ('K', 'V', '0')) THEN
            v_precio_exportacion = 'PVP DISTRIBUIDOR*1.85. El precio se redondea a dos decimales';
        ELSEIF (LEFT(p_item, 1) = '6' AND SUBSTR(p_item, 14, 1) IN ('0', '4')) THEN
            v_precio_exportacion = 'PVP DISTRIBUIDOR*1.85. El precio se redondea a dos decimales';
        END IF;
    END IF;

    -- PRECIO OFERTA
    IF LEFT(p_item, 1) IN ('1', '5') THEN
        IF (LEFT(p_item, 2) NOT IN ('1W', '1Y', '1X', '1V') AND LEFT(p_item, 1) != '5') OR
           (LEFT(p_item, 1) = '5' AND SUBSTR(p_item, 14, 1) = '0') THEN
            v_precio_oferta =
                    '(PVP/2)*IVA, si precio <$20 y la fracción <.50 se convierte a .47, caso contrario .97, si precio>$20 la fracción=.97';
        END IF;

    ELSEIF LEFT(p_item, 1) IN ('6', '2', '3', '4') THEN
        IF (LEFT(p_item, 1) = '2' AND SUBSTR(p_item, 14, 1) IN ('4', '0')) THEN
            v_precio_oferta = 'A Mitad de Precio del PVP. El precio se redondea a dos decimales';
        ELSEIF (LEFT(p_item, 1) = '3' AND SUBSTR(p_item, 14, 1) IN ('K', 'V', '0')) THEN
            v_precio_oferta = 'A Mitad de Precio del PVP. El precio se redondea a dos decimales';
        ELSEIF (LEFT(p_item, 1) = '6' AND SUBSTR(p_item, 14, 1) IN ('0', '4')) THEN
            v_precio_oferta = 'A Mitad de Precio del PVP. El precio se redondea a dos decimales';
        END IF;
    END IF;

    RETURN QUERY
        SELECT v_precio_distribuidor AS precio_distribuidor,
               v_precio_mayorista    AS precio_mayorista,
               v_precio_mercantil    AS precio_mercantil,
               v_precio_cadena       AS precio_cadena,
               v_precio_exportacion  AS precio_exportacion,
               v_precio_oferta       AS precio_oferta;
END;
$function$
;
