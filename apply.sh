#!/bin/bash
# Script pour générer et appliquer toutes les pages d'erreur directement au conteneur

# Vérifier que le conteneur est en cours d'exécution
if ! docker inspect nginx-proxy-manager --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    echo "❌ Le conteneur nginx-proxy-manager n'est pas en cours d'exécution."
    echo "   Lancez-le avec : docker compose up -d"
    exit 1
fi

echo "🔄 Génération et déploiement des pages d'erreur..."

# Codes d'erreur à déployer
ERROR_CODES=(401 403 404 408 429 500 502 503)

for ERROR_CODE in "${ERROR_CODES[@]}"; do
    TEMPLATE="templates/${ERROR_CODE}.html"
    
    # Vérifier que le template existe
    if [ ! -f "$TEMPLATE" ]; then
        echo "⚠️  Template manquant: $TEMPLATE (skipped)"
        continue
    fi
    
    # Générer et envoyer
    python3 << PYTHON | docker exec -i nginx-proxy-manager bash -c "cat > /var/www/html/error${ERROR_CODE}.html" || { echo "❌ Erreur lors du déploiement de error${ERROR_CODE}.html"; exit 1; }
import base64

# Read template
with open('templates/$ERROR_CODE.html', 'r') as f:
    template = f.read()

# Replace image placeholder only for 403
if '$ERROR_CODE' == '403':
    with open('image.webp', 'rb') as f:
        image_data = f.read()
    b64_image = base64.b64encode(image_data).decode('utf-8')
    html_content = template.replace('{BASE64_IMAGE}', b64_image)
else:
    html_content = template

# Output to stdout (will be piped to docker)
print(html_content)
PYTHON
    
    echo "  ✅ error${ERROR_CODE}.html généré et déployé"
done

# Déployer les configs nginx
echo "🔧 Déploiement de la configuration nginx..."

docker cp nginx/http.conf nginx-proxy-manager:/data/nginx/custom/http.conf || { echo "❌ Erreur nginx/http.conf"; exit 1; }
echo "  ✅ nginx/http.conf déployé"

docker cp nginx/server-proxy.conf nginx-proxy-manager:/data/nginx/custom/server_proxy.conf || { echo "❌ Erreur nginx/server-proxy.conf"; exit 1; }
echo "  ✅ nginx/server-proxy.conf déployé"

docker cp nginx/default-site.conf nginx-proxy-manager:/data/nginx/default_host/site.conf || { echo "❌ Erreur nginx/default-site.conf"; exit 1; }
echo "  ✅ nginx/default-site.conf déployé"

# Reload nginx
docker exec nginx-proxy-manager nginx -s reload

echo "✅ Tous les fichiers ont été déployés et nginx a été rechargé !"
