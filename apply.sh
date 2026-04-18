#!/bin/bash
# Script pour générer et appliquer toutes les pages d'erreur directement au conteneur

# Vérifier que le conteneur est en cours d'exécution
if ! docker inspect nginx-proxy-manager --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    echo "❌ Le conteneur nginx-proxy-manager n'est pas en cours d'exécution."
    echo "   Lancez-le avec : docker compose up -d"
    exit 1
fi

echo "🔄 Génération et déploiement des pages d'erreur..."

# Codes d'erreur → [CODE]="Titre|Message"
declare -A ERROR_PAGES=(
    [401]="Non Authentifié - Erreur 401|Erreur 401 - Authentification Requise"
    [404]="Page Non Trouvée - Erreur 404|Erreur 404 - Page Non Trouvée"
    [408]="Délai Expiré - Erreur 408|Erreur 408 - Délai Expiré"
    [429]="Trop de Requêtes - Erreur 429|Erreur 429 - Trop de Requêtes"
    [500]="Erreur Serveur - Erreur 500|Erreur 500 - Erreur Serveur"
    [502]="Mauvaise Passerelle - Erreur 502|Erreur 502 - Mauvaise Passerelle"
    [503]="Service Indisponible - Erreur 503|Erreur 503 - Service Indisponible"
)

# Pages génériques depuis template/error.html
for ERROR_CODE in "${!ERROR_PAGES[@]}"; do
    TITLE="${ERROR_PAGES[$ERROR_CODE]%%|*}"
    MESSAGE="${ERROR_PAGES[$ERROR_CODE]##*|}"

    python3 << PYTHON | docker exec -i nginx-proxy-manager bash -c "cat > /var/www/html/error${ERROR_CODE}.html" || { echo "❌ Erreur lors du déploiement de error${ERROR_CODE}.html"; exit 1; }
with open('templates/error.html', 'r') as f:
    template = f.read()

html_content = template.replace('{TITLE}', '$TITLE').replace('{CODE}', '$ERROR_CODE').replace('{MESSAGE}', '$MESSAGE')
print(html_content)
PYTHON

    echo "  ✅ error${ERROR_CODE}.html généré et déployé"
done

# Page 403 spéciale (avec image)
python3 << PYTHON | docker exec -i nginx-proxy-manager bash -c "cat > /var/www/html/error403.html" || { echo "❌ Erreur lors du déploiement de error403.html"; exit 1; }
import base64

with open('templates/403.html', 'r') as f:
    template = f.read()

with open('image.webp', 'rb') as f:
    image_data = f.read()

b64_image = base64.b64encode(image_data).decode('utf-8')
html_content = template.replace('{BASE64_IMAGE}', b64_image)
print(html_content)
PYTHON
echo "  ✅ error403.html généré et déployé"

# Déployer les configs nginx
echo "🔧 Déploiement de la configuration nginx..."

docker cp nginx/http.conf nginx-proxy-manager:/data/nginx/custom/http.conf || { echo "❌ Erreur nginx/http.conf"; exit 1; }
echo "  ✅ nginx/http.conf déployé"

docker cp nginx/server-proxy.conf nginx-proxy-manager:/data/nginx/custom/server_proxy.conf || { echo "❌ Erreur nginx/server-proxy.conf"; exit 1; }
echo "  ✅ nginx/server-proxy.conf déployé"

# Générer le certificat auto-signé pour le default SSL si nécessaire
docker exec nginx-proxy-manager bash -c "
  if [ ! -f /data/nginx/ssl-default/default.crt ]; then
    mkdir -p /data/nginx/ssl-default
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
      -keyout /data/nginx/ssl-default/default.key \
      -out /data/nginx/ssl-default/default.crt \
      -subj '/CN=default' 2>/dev/null
    echo 'créé'
  else
    echo 'existe'
  fi
" | grep -q créé && echo "  ✅ Certificat SSL auto-signé généré" || echo "  ✅ Certificat SSL auto-signé déjà présent"

docker cp nginx/default-site.conf nginx-proxy-manager:/data/nginx/default_host/site.conf || { echo "❌ Erreur nginx/default-site.conf"; exit 1; }
echo "  ✅ nginx/default-site.conf déployé"

# Reload nginx
docker exec nginx-proxy-manager nginx -s reload

echo "✅ Tous les fichiers ont été déployés et nginx a été rechargé !"
