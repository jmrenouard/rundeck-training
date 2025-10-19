#!/bin/sh

# 1. Vérifie si une URL est fournie
if [ -z "$1" ]; then
  echo "Erreur : Vous devez fournir l'URL du site cible."
  echo "Usage: $0 https://www.example.com"
  exit 1
fi

TARGET_SITE="$1"
# Crée un nom de fichier basé sur l'URL (ex: www.example.com.pdf)
OUTPUT_FILENAME=$(echo "$TARGET_SITE" | sed -e 's/https\?:\/\///' -e 's/\/$//' -e 's/\//-/g').pdf

# 2. Créer un répertoire de travail temporaire
WORKDIR="pdf_conversion_temp"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "Étape 1/3 : Recherche des URLs sur $TARGET_SITE..."

# 3. Utilise wget pour trouver toutes les URLs (récursivement, niveau 2)
# et les filtre pour ne garder que les pages HTML.
wget --spider --force-html -r -l2 "$TARGET_SITE" 2>&1 | \
  grep '^--' | awk '{ print $3 }' | \
  grep -v '\.\(css\|js\|png\|gif\|jpg\|txt\)$' > url-list.txt

echo "Étape 2/3 : Conversion des URLs en PDF..."

# 4. Boucle sur chaque URL et la convertit en PDF
# Le nom du fichier PDF est basé sur l'URL pour éviter les conflits
while read i; do
  echo "Conversion de : $i"
  wkhtmltopdf "$i" "$(echo "$i" | sed -e 's/https\?:\/\///' -e 's/\//-/g' ).pdf"
done < url-list.txt

echo "Étape 3/3 : Fusion de tous les PDF..."

# 5. Fusionne tous les PDF générés en un seul fichier
# Utilise ghostscript pour une fusion efficace
gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress \
   -sOutputFile=../"$OUTPUT_FILENAME" *.pdf

# 6. Nettoyage
cd ..
rm -rf "$WORKDIR"

echo "Terminé ! Le fichier PDF a été sauvegardé sous : $OUTPUT_FILENAME"