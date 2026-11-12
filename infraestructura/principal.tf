terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Proyecto = var.proyecto
    }
  }
}

data "aws_caller_identity" "actual" {}

locals {
  # Si no se indica un nombre, se genera uno único con el ID de la cuenta.
  nombre_bucket = var.nombre_bucket != "" ? var.nombre_bucket : "${var.proyecto}-${data.aws_caller_identity.actual.account_id}"

  prefijo_datos      = "entregas/"
  prefijo_resultados = "resultados-athena/"
}

# ---------------------------------------------------------------------------
# 1. Bucket S3 privado con bloqueo de acceso público
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "datos" {
  bucket        = local.nombre_bucket
  force_destroy = true # permite que terraform destroy elimine el bucket aunque tenga objetos
}

resource "aws_s3_bucket_public_access_block" "datos" {
  bucket = aws_s3_bucket.datos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "datos" {
  bucket = aws_s3_bucket.datos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ---------------------------------------------------------------------------
# 2. Prefijos separados (marcadores vacíos; los prefijos son parte de la clave)
# ---------------------------------------------------------------------------
resource "aws_s3_object" "prefijo_entregas" {
  bucket  = aws_s3_bucket.datos.id
  key     = local.prefijo_datos
  content = ""
}

resource "aws_s3_object" "prefijo_resultados" {
  bucket  = aws_s3_bucket.datos.id
  key     = local.prefijo_resultados
  content = ""
}

# ---------------------------------------------------------------------------
# 3. Base de datos de Glue Data Catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "entregas" {
  name        = var.nombre_base_datos
  description = "Catalogo de intentos de entrega de paquetes"
}

# ---------------------------------------------------------------------------
# 4. Tabla externa con partition projection por fecha
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_table" "entregas" {
  name          = var.nombre_tabla
  database_name = aws_glue_catalog_database.entregas.name
  table_type    = "EXTERNAL_TABLE"
  description   = "Intentos de entrega en CSV, particionados por fecha mediante partition projection"

  parameters = {
    "EXTERNAL"               = "TRUE"
    "classification"         = "csv"
    "skip.header.line.count" = "1"

    # Partition projection: Athena calcula las particiones en cada consulta.
    "projection.enabled"             = "true"
    "projection.fecha.type"          = "date"
    "projection.fecha.format"        = "yyyy-MM-dd"
    "projection.fecha.range"         = "${var.fecha_inicio},${var.fecha_fin}"
    "projection.fecha.interval"      = "1"
    "projection.fecha.interval.unit" = "DAYS"

    # Prefijo de cada partición (termina en /). $${fecha} escapa la interpolación de Terraform.
    "storage.location.template" = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}fecha=$${fecha}/"
  }

  partition_keys {
    name = "fecha"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_datos}"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "csv"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "field.delim"          = ","
        "serialization.format" = ","
      }
    }

    columns {
      name    = "id_envio"
      type    = "string"
      comment = "Identificador unico del envio"
    }

    columns {
      name    = "ciudad"
      type    = "string"
      comment = "Ciudad del intento de entrega"
    }

    columns {
      name    = "transportadora"
      type    = "string"
      comment = "Transportadora responsable"
    }

    columns {
      name    = "estado"
      type    = "string"
      comment = "entregado, destinatario_ausente o direccion_incorrecta"
    }

    columns {
      name    = "duracion_minutos"
      type    = "int"
      comment = "Duracion en minutos; 0 en intentos fallidos"
    }
  }
}

# ---------------------------------------------------------------------------
# 5. Workgroup de Athena con resultados en resultados-athena/
# ---------------------------------------------------------------------------
resource "aws_athena_workgroup" "entregas" {
  name          = var.nombre_workgroup
  description   = "Workgroup del ejercicio de entregas"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datos.bucket}/${local.prefijo_resultados}"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}
