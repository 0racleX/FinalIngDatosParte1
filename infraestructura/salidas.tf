output "bucket" {
  description = "Nombre del bucket S3"
  value       = aws_s3_bucket.datos.bucket
}

output "bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.datos.arn
}

output "ruta_entregas" {
  description = "Prefijo S3 de los datos"
  value       = "s3://${aws_s3_bucket.datos.bucket}/${aws_s3_object.prefijo_entregas.key}"
}

output "ruta_resultados_athena" {
  description = "Prefijo S3 de los resultados de Athena"
  value       = "s3://${aws_s3_bucket.datos.bucket}/${aws_s3_object.prefijo_resultados.key}"
}

output "base_datos" {
  description = "Base de datos de Glue"
  value       = aws_glue_catalog_database.entregas.name
}

output "tabla" {
  description = "Tabla externa con partition projection"
  value       = aws_glue_catalog_table.entregas.name
}

output "workgroup" {
  description = "Workgroup de Athena"
  value       = aws_athena_workgroup.entregas.name
}

output "region" {
  description = "Region del despliegue"
  value       = var.region
}
