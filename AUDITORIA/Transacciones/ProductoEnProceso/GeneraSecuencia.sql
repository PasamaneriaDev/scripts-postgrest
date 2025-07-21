CREATE FUNCTION sistema.get_secuencia_from_parametros(p_modulo varchar, p_codigo varchar, OUT p_secuencia integer) RETURNS integer
    LANGUAGE plpgsql
AS
$$
BEGIN

    UPDATE sistema.parametros
        SET numero = numero + 1
	where  modulo_id = p_modulo
	 	and codigo = p_codigo
    RETURNING numero::integer INTO p_secuencia;

END
$$;
