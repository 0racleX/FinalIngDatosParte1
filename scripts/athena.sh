#!/usr/bin/env bash
# Ejecuta UNA sentencia de un archivo .sql en Athena, guarda el resultado como CSV
# y registra la ejecucion en evidencias/ejecuciones_athena.csv.
#
# Uso: bash scripts/athena.sh <etapa> <archivo_sql> <archivo_resultado> [numero_sentencia]
#   etapa: inicial | final
#   numero_sentencia: 1 por defecto (para archivos con varias consultas separadas por ';')
set -euo pipefail
cd "$(dirname "$0")/.."

etapa="$1"; archivo_sql="$2"; archivo_resultado="$3"; n="${4:-1}"
registro="evidencias/ejecuciones_athena.csv"

workgroup=$(jq -r '.workgroup.value' evidencias/outputs.json)
base_datos=$(jq -r '.base_datos.value' evidencias/outputs.json)
region=$(jq -r '.region.value' evidencias/outputs.json)

# Quita comentarios '--' y toma la sentencia numero n (separadas por ';').
sql=$(sed 's/--.*$//' "$archivo_sql" | awk -v n="$n" 'BEGIN{RS=";"} NR==n{print}')
if [ -z "$(echo "$sql" | tr -d '[:space:]')" ]; then
    echo "No se encontro la sentencia $n en $archivo_sql" >&2; exit 1
fi

id=$(aws athena start-query-execution \
    --region "$region" \
    --work-group "$workgroup" \
    --query-execution-context "Database=$base_datos" \
    --query-string "$sql" \
    --query 'QueryExecutionId' --output text)
echo "Ejecucion: $id"

while :; do
    estado=$(aws athena get-query-execution --region "$region" --query-execution-id "$id" \
        --query 'QueryExecution.Status.State' --output text)
    case "$estado" in
        SUCCEEDED) break ;;
        FAILED|CANCELLED)
            aws athena get-query-execution --region "$region" --query-execution-id "$id" \
                --query 'QueryExecution.Status.StateChangeReason' --output text >&2
            exit 1 ;;
        *) sleep 2 ;;
    esac
done

# Convierte el resultado a CSV sin comillas (los valores no contienen comas).
mkdir -p "$(dirname "$archivo_resultado")"
aws athena get-query-results --region "$region" --query-execution-id "$id" --output json \
    | jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue // ""] | join(",")' > "$archivo_resultado"

[ -f "$registro" ] || echo "etapa,archivo_sql,id_ejecucion,archivo_resultado" > "$registro"
echo "$etapa,$archivo_sql,$id,$archivo_resultado" >> "$registro"

echo "Resultado guardado en $archivo_resultado:"
cat "$archivo_resultado"
