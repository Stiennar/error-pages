# Error Pages - Nginx Proxy Manager

Pages d'erreur personnalisées et responsive pour nginx-proxy-manager (401, 403, 404, 500, 502, 503).

## 📁 Structure

```
.
├── template-401.html    ← Authentification requise
├── template-403.html    ← Accès refusé
├── template-404.html    ← Page non trouvée
├── template-500.html    ← Erreur serveur
├── template-502.html    ← Mauvaise passerelle
├── template-503.html    ← Service indisponible
├── image.webp           ← Image source (remplacer pour une nouvelle image)
├── apply.sh             ← Script de déploiement (génère + envoie tous les fichiers)
├── pull.sh              ← Récupère les pages depuis la prod
└── README.md
```

## ⚡ Workflow

### Déployer tous les changements
```bash
bash apply.sh
```
→ Génère tous les fichiers d'erreur depuis les templates + image
→ Envoie directement au conteneur
→ Recharge nginx

### Récupérer depuis la prod
```bash
bash pull.sh
```

## 🎨 Personnalisation

### Éditer le texte ou le design
Modifier les fichiers `template-XXX.html` :
- **401** : Authentification requise
- **403** : Accès refusé
- **404** : Page non trouvée
- **500** : Erreur serveur
- **502** : Mauvaise passerelle
- **503** : Service indisponible

Chaque template contient :
- Titre : `<h1>...</h1>`
- Texte : `<p>...</p>`
- CSS : Dans le bloc `<style>`

### Changer l'image
1. Remplacer `image.webp` par votre image
2. Lancer `bash apply.sh`
3. Tous les fichiers seront régénérés avec la nouvelle image

## 🔧 Détails techniques

- **HTML** : Responsive via `clamp()` pour le font-size
- **Image** : Base64 incluse inline (pas d'appel externe)
- **Layout** : Flexbox, h1 en haut, image au centre, texte en bas
- **Effects** : Drop-shadow transparent sur l'image avec dégradé
- **Localisation** : `/var/www/html/error401.html`, `error403.html`, etc. dans le conteneur

## 📋 Notes

- Les fichiers `error*.html` sont **générés** à chaque déploiement (ne pas éditer directement)
- Le placeholder `{BASE64_IMAGE}` dans chaque template est remplacé automatiquement
- Les pages sont optimisées pour tous les écrans (mobile, tablet, desktop)
- Chaque code d'erreur a son propre template pour plus de flexibilité

## 🔗 Configuration Nginx

Pour utiliser ces pages, configurez nginx comme suit :

```nginx
error_page 401 /error401.html;
error_page 403 /error403.html;
error_page 404 /error404.html;
error_page 500 /error500.html;
error_page 502 /error502.html;
error_page 503 /error503.html;
```

Enjoy! 🎉
