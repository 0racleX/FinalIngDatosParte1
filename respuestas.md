# Respuestas

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Porque la tabla `entregas` no depende de particiones registradas en Glue: tiene `projection.enabled = true`
y reglas para la clave `fecha` (tipo `date`, formato `yyyy-MM-dd`, rango `2026-10-01,2026-10-03`, intervalo de
1 día). En cada consulta Athena calcula los valores posibles de `fecha` a partir de esas reglas y arma la
ruta de cada uno con `storage.location.template` (`s3://<bucket>/entregas/fecha=${fecha}/`).

Desde el `terraform apply` inicial, el 2026-10-03 ya estaba dentro del rango proyectado. En la etapa inicial
Athena también buscaba ese prefijo, pero no había objetos y por eso no devolvía filas (12 registros). Al subir
`entregas/fecha=2026-10-03/entregas.csv`, el prefijo que Athena ya calculaba dejó de estar vacío y la siguiente
consulta leyó el archivo. La evidencia está en `resultados/final/verificacion_tercer_dia.csv` (6 registros),
`resultados/final/total_registros.csv` (18 registros) y en los IDs de la etapa `final` de
`evidencias/ejecuciones_athena.csv`. En ese paso no se cambió Terraform ni se ejecutó ningún crawler,
`MSCK REPAIR TABLE` o `ALTER TABLE ADD PARTITION`.

## 2. ¿Qué pasaría con un archivo del 4 de octubre manteniendo la configuración actual?

El archivo se guardaría en S3, pero Athena no lo leería. El rango proyectado termina en `2026-10-03`, así que
`2026-10-04` no está entre los valores que Athena genera. Una consulta con `WHERE fecha = '2026-10-04'`
devolvería cero filas sin error, y los agregados y el total seguirían mostrando solo tres días (18 registros).

Para incluirlo hay que ampliar el rango de la proyección **en Terraform**, por ejemplo con
`fecha_fin = "2026-10-04"` (o un rango abierto como `2026-10-01,NOW`), y ejecutar `terraform apply`. Eso
actualiza la propiedad `projection.fecha.range` de la tabla. Después basta con consultar, sin registrar
particiones. Si la consulta tiene un filtro de fechas explícito (como el `BETWEEN` de los SQL de este
repositorio), también hay que ampliarlo.
