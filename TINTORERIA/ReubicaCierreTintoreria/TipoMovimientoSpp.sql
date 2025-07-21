-- DROP FUNCTION LISTA_MATERIALES.TIPO_MOVIMIENTO_SPP_X_CODIGO(text, text);

CREATE OR REPLACE FUNCTION lista_materiales.tipo_movimiento_spp_x_codigo(p_codigo text, OUT o_tipo_spp text)
    RETURNS text
    LANGUAGE plpgsql
AS
$fucntion$
BEGIN
    SELECT tipo_spp
    INTO o_tipo_spp
    FROM lista_materiales.tipo_movimiento tm
    WHERE codigo = p_codigo;
END;
$fucntion$
;

SELECT lista_materiales.tipo_movimiento_spp_x_codigo('AJUS CANT+')