SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3',



SELECT *
FROM cuentas_cobrar.facturas_cabecera
WHERE creacion_fecha > '20250101'
  AND cliente = '000273'

CREATE TABLE public.prueba_tabla_fisica AS
SELECT *
FROM control_inventarios.items
LIMIT 10


SELECT *
FROM public.prueba_tabla_fisica IF BanderaReporte='Actual'
	SEEK 'FEC_VIGE_PRECIO'
	Thisform.TxtFecha.ReadOnly=.T.
ELSE
	SEEK 'FEC_VIG_PREC_PR'
	Thisform.TxtFecha.ReadOnly=.F.
ENDIF


SELECT fecha
FROM sistema.parametros p
WHERE codigo = 'FEC_VIGE_PRECIO';



