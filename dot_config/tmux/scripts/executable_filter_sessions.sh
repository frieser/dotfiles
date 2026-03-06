#!/bin/bash
SAVE_FILE="$1"
[ -f "$SAVE_FILE" ] || exit 1

TMP_FINAL="${SAVE_FILE}.final"

awk -F'\t' '
  ($1=="pane" || $1=="window" || $1=="session") && $2 !~ /^[0-9]+$/ { found=1; exit } 
  END { if (!found) exit 1 }
' "$SAVE_FILE"

if [ $? -eq 0 ]; then
  awk -F'\t' '
    $1 == "grouped_session" { if ($2 !~ /^[0-9]+$/ && $3 !~ /^[0-9]+$/) print $0; next; }
    $1 == "state" { if ($3 !~ /^[0-9]+$/) print $0; next; }
    $2 !~ /^[0-9]+$/ { print $0; }
  ' "$SAVE_FILE" > "$TMP_FINAL"
  mv "$TMP_FINAL" "$SAVE_FILE"

else
  ACTIVE_SESSION=$(awk -F'\t' '$1=="state" {print $3; exit}' "$SAVE_FILE")
  
  if [ -z "$ACTIVE_SESSION" ]; then
    ACTIVE_SESSION=$(awk -F'\t' '($1=="pane" || $1=="window") && $2 ~ /^[0-9]+$/ {print $2; exit}' "$SAVE_FILE")
  fi
  
  awk -F'\t' -v target="$ACTIVE_SESSION" '
    $1 != "state" && $2 == target { print $0 }
  ' "$SAVE_FILE" > "$TMP_FINAL"
  
  mv "$TMP_FINAL" "$SAVE_FILE"
fi
