Respuestas
1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?
La proyección ya incluía el día 3 desde que se hizo el apply al principio de todo, y athena calcula la ruta en cada consulta, antes no había archivo, cuando lo subí se leyó y paso a 18.
Esto se ve en como no hay particiones y hay 18 registros.

2. ¿Qué pasaría con un archivo del 4 de octubre manteniendo la configuración actual?

El 4 de Octubre esta fuera del rango, por eso da 0 filas sin error alguno, para incluirlo hay que cambiar la fecha fin en Terraform, hacer el apply y ampliar la query between en sql.
