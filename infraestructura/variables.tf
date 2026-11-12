variable "region" {
  description = "Region de AWS donde se despliegan los recursos"
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo usado en nombres y etiquetas"
  type        = string
  default     = "de-final-entregas"
}

variable "nombre_bucket" {
  description = "Nombre del bucket S3. Si se deja vacio se usa <proyecto>-<id de la cuenta>"
  type        = string
  default     = ""
}

variable "nombre_base_datos" {
  description = "Nombre de la base de datos de Glue Data Catalog"
  type        = string
  default     = "entregas_db"
}

variable "nombre_tabla" {
  description = "Nombre de la tabla externa"
  type        = string
  default     = "entregas"
}

variable "nombre_workgroup" {
  description = "Nombre del workgroup de Athena"
  type        = string
  default     = "entregas_wg"
}

variable "fecha_inicio" {
  description = "Primera fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-01"
}

variable "fecha_fin" {
  description = "Ultima fecha proyectada (yyyy-MM-dd), incluida"
  type        = string
  default     = "2026-10-03"
}
