#!/bin/bash
# Script pour récupérer les fichiers du conteneur

# Vérifier que le conteneur est en cours d'exécution
if ! docker inspect nginx-proxy-manager --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    echo "❌ Le conteneur nginx-proxy-manager n'est pas en cours d'exécution."
    exit 1
fi

echo "📥 Récupération de la configuration nginx..."

# Config nginx → nginx/
# (les pages HTML ne sont pas récupérées : elles sont générées depuis templates/ par apply.sh)
docker cp nginx-proxy-manager:/data/nginx/custom/http.conf ./nginx/http.conf 2>/dev/null \
    && echo "  ✅ nginx/http.conf" \
    || echo "  ⚠️  nginx/http.conf non trouvée"

docker cp nginx-proxy-manager:/data/nginx/custom/server_proxy.conf ./nginx/server-proxy.conf 2>/dev/null \
    && echo "  ✅ nginx/server-proxy.conf" \
    || echo "  ⚠️  nginx/server-proxy.conf non trouvée"

docker cp nginx-proxy-manager:/data/nginx/default_host/site.conf ./nginx/default-site.conf 2>/dev/null \
    && echo "  ✅ nginx/default-site.conf" \
    || echo "  ⚠️  nginx/default-site.conf non trouvée"

echo "✅ Récupération terminée !"
