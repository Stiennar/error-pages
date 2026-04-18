#!/bin/bash
# Script pour générer et appliquer toutes les pages d'erreur directement au conteneur

# Vérifier que le conteneur est en cours d'exécution
if ! docker inspect nginx-proxy-manager --format '{{.State.Running}}' 2>/dev/null | grep -q true; then
    echo "❌ Le conteneur nginx-proxy-manager n'est pas en cours d'exécution."
    echo "   Lancez-le avec : docker compose up -d"
    exit 1
fi

echo "🔄 Génération et déploiement des pages d'erreur..."

python3 << 'PYTHON' || { echo "❌ Erreur lors de la génération des pages"; exit 1; }
import base64, subprocess

ERROR_PAGES = {
    "401": "Authentification Requise",
    "404": "Page Non Trouvée",
    "408": "Délai Expiré",
    "429": "Trop de Requêtes",
    "500": "Erreur Serveur",
    "502": "Mauvaise Passerelle",
    "503": "Service Indisponible",
}

template = open("templates/error.html").read()

for code, description in ERROR_PAGES.items():
    html = template.replace("{TITLE}", f"Erreur {code}").replace("{CODE}", code).replace("{MESSAGE}", description)
    cmd = ["docker", "exec", "-i", "nginx-proxy-manager", "bash", "-c", f"cat > /var/www/html/error{code}.html"]
    subprocess.run(cmd, input=html.encode(), check=True)
    print(f"  ✅ error{code}.html généré et déployé")

# Page 403 spéciale (avec image)
template_403 = open("templates/403.html").read()
b64_image = base64.b64encode(open("image.webp", "rb").read()).decode()
html_403 = template_403.replace("{BASE64_IMAGE}", b64_image)
cmd = ["docker", "exec", "-i", "nginx-proxy-manager", "bash", "-c", "cat > /var/www/html/error403.html"]
subprocess.run(cmd, input=html_403.encode(), check=True)
print("  ✅ error403.html généré et déployé")
PYTHON

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
docker exec nginx-proxy-manager nginx -s reload || { echo "❌ nginx reload échoué (config invalide ?)"; exit 1; }

echo "✅ Tous les fichiers ont été déployés et nginx a été rechargé !"
