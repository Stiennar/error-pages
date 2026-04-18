# Error Pages - Nginx Proxy Manager

Pages d'erreur personnalisées et responsive pour nginx-proxy-manager.

Codes supportés : **401, 403, 404, 408, 429, 500, 502, 503**

## 📁 Structure

```
.
├── templates/           ← Sources HTML (à éditer)
│   ├── error.html       Template générique (401, 404, 408, 429, 500, 502, 503)
│   └── 403.html         Accès refusé (avec image)
├── nginx/               ← Configs nginx (versionnées)
│   ├── http.conf        error_page globaux
│   ├── server-proxy.conf  proxy_intercept_errors + locations
│   └── default-site.conf  Domaines inconnus → 404
├── image.webp           ← Image exclusive au 403
├── apply.sh             ← Déploiement complet
├── pull.sh              ← Backup des configs nginx
└── README.md
```

## ⚡ Workflow

### Déployer tous les changements
```bash
bash apply.sh
```
→ Génère les 8 pages d'erreur depuis `templates/error.html` (+ `403.html` avec image)  
→ Déploie les configs `nginx/`  
→ Recharge nginx

### Backup des configs nginx depuis le serveur
```bash
bash pull.sh
```

### Restauration complète (nouveau conteneur)
```bash
git clone https://github.com/Stiennar/error-pages.git
cd error-pages
bash apply.sh
```

## 🎨 Personnalisation

### Éditer le texte ou le design
Modifier `templates/error.html` (pages génériques) ou `templates/403.html` (page spéciale) :
- Code affiché : `<h1>{CODE}</h1>`
- Message : `<p>Erreur {CODE} - {MESSAGE}</p>` — les textes sont dans `apply.sh` (dict `ERROR_PAGES`)
- Style : bloc `<style>`

Puis redéployer :
```bash
bash apply.sh
```

### Changer l'image (403 uniquement)
1. Remplacer `image.webp`
2. Lancer `bash apply.sh`

## 🔧 Architecture nginx

| Fichier | Rôle | Emplacement conteneur |
|---------|------|-----------------------|
| `nginx/http.conf` | `error_page` globaux | `/data/nginx/custom/http.conf` |
| `nginx/server-proxy.conf` | `proxy_intercept_errors`, `proxy_hide_header`, locations `internal` | `/data/nginx/custom/server_proxy.conf` |
| `nginx/default-site.conf` | Domaines inconnus → 404 personnalisé | `/data/nginx/default_host/site.conf` |

Les fichiers dans `/data/nginx/` sont **persistants** via volume Docker — ils survivent aux redémarrages du conteneur.

## 📋 Notes

- Les fichiers `error*.html` sont **générés** par `apply.sh` (ignorés par git)
- L'image est encodée en base64 inline — aucun appel externe
- `proxy_hide_header WWW-Authenticate` évite la fenêtre de login native du navigateur sur les 401
- Les pages sont responsive (mobile, tablet, desktop) via `clamp()` et flexbox

