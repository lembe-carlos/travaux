# SAHEL BTP — Gestion des matériaux

Application de gestion des matériaux BTP, en **HTML / CSS / JavaScript pur**
(aucun framework, aucune étape de build). Fonctionne directement dans un
navigateur, hébergeable sur GitHub Pages en glissant simplement les fichiers.

## Fichiers du projet

```
index.html            page principale (structure)
style.css              tous les styles
app.js                 toute la logique de l'application
config.js               vos identifiants Supabase (à remplir)
supabase-schema.sql     script SQL à exécuter dans Supabase
```

## Mode de fonctionnement : LOCAL par défaut, DYNAMIQUE une fois connecté

**Aucune donnée fictive n'est incluse.** Au tout premier lancement, l'application
est entièrement vide et vous demande de créer votre propre compte administrateur
(nom, e-mail, mot de passe de votre choix). Ce compte a tous les droits. Vous
créez ensuite vous-même vos matériaux, dépôts, fournisseurs, chantiers,
utilisateurs, etc. — rien n'est pré-rempli.

**Tel quel (sans configurer Supabase)**, les données restent stockées dans le
navigateur (localStorage) — elles ne sont pas partagées entre appareils ou
utilisateurs.

**Pour rendre l'application réellement dynamique** (données partagées en
temps réel entre tous les utilisateurs et appareils, comme une vraie
application professionnelle), il faut la connecter à une base de données
Supabase gratuite. Une fois connectée, un badge **"En ligne"** apparaît en
haut de l'application, et toutes les créations/modifications sont
automatiquement envoyées à la base partagée, avec une resynchronisation
automatique toutes les 20 secondes pour récupérer les changements faits par
d'autres.

### Étapes de connexion (10 minutes, une seule fois)

1. Créez un compte gratuit sur **supabase.com** et créez un nouveau projet.
2. Dans le projet, allez dans **SQL Editor → New query**, collez tout le
   contenu du fichier `supabase-schema.sql` fourni ici, puis cliquez **Run**.
   Cela crée toutes les tables nécessaires.
3. Allez dans **Project Settings → API**. Copiez :
   - **Project URL**
   - la clé **anon public**
4. Ouvrez `config.js` et collez ces deux valeurs :
   ```js
   const CONFIG = {
     SUPABASE_URL: "https://xxxxxxxx.supabase.co",
     SUPABASE_ANON_KEY: "eyJhbGciOi...",
   };
   ```
5. Ouvrez (ou republiez) `index.html` — l'application se connecte
   automatiquement. Le premier écran vous invite à créer votre compte
   administrateur, qui sera alors enregistré directement dans Supabase.

### ⚠️ Note de sécurité importante

Cette application utilise la clé publique Supabase directement dans le
navigateur, avec des règles d'accès ouvertes (voir `supabase-schema.sql`).
Cela veut dire que **toute personne connaissant votre URL et votre clé
pourrait techniquement lire ou modifier les données** en contournant
l'interface. C'est un compromis raisonnable pour un usage interne à l'équipe
Sahel BTP, mais **ne convient pas à une mise en production grand public**
sans ajouter une vraie authentification (Supabase Auth) et des règles de
sécurité par utilisateur — une évolution possible plus tard.

## Comptes et authentification

Il n'existe aucun compte préconfiguré. Le premier écran vous invite à créer
votre propre compte administrateur.

**En mode connecté (Supabase configuré)** — vraie authentification via
**Supabase Auth** :
- Mots de passe chiffrés côté serveur (jamais stockés en clair)
- Chaque nouveau membre crée son propre compte en libre-service (bouton
  « Créer un compte » sur l'écran de connexion) — le tout premier compte créé
  devient automatiquement Super Administrateur ; les suivants ont un accès
  limité en attendant qu'un administrateur leur attribue un rôle depuis la
  page **Utilisateurs**
- **Vrai bouton « Mot de passe oublié »** : un e-mail de réinitialisation est
  envoyé par Supabase, avec un lien qui ramène sur l'application pour choisir
  un nouveau mot de passe
- ⚠️ Par défaut, Supabase exige de confirmer son adresse e-mail avant de
  pouvoir se connecter. Si l'e-mail n'arrive pas (vérifiez les spams), vous
  pouvez désactiver cette exigence pour vos tests dans Supabase :
  **Authentication → Providers → Email → décochez "Confirm email"**.

**En mode local (sans Supabase)** — système simplifié sans backend :
- Les comptes sont stockés dans le navigateur ; un administrateur peut
  modifier le mot de passe de quelqu'un directement depuis la page
  Utilisateurs (pas d'envoi d'e-mail possible sans serveur)
- Le bouton « Mot de passe oublié » explique cette limitation

**Si vous aviez déjà exécuté une version précédente de**
**`supabase-schema.sql`** (avant l'ajout de la vraie authentification),
**exécutez à nouveau tout le fichier** dans l'éditeur SQL : il contient une
migration automatique (colonne `password` rendue facultative, règles de
sécurité mises à jour pour exiger une session authentifiée) — sans danger,
rien n'est supprimé.

## Installation sur téléphone (PWA)

L'application est maintenant installable comme une vraie application, sur
Android et iPhone.

**Sur Android (Chrome) :** ouvrez l'application, allez dans **Paramètres**
et appuyez sur **"Installer l'application"** — ou utilisez le menu ⋮ du
navigateur → "Installer l'application".

**Sur iPhone (Safari) :** ouvrez l'application dans Safari, appuyez sur le
bouton **Partager** (le carré avec une flèche), puis **"Sur l'écran
d'accueil"**. (iOS ne permet pas l'installation automatique en un clic comme
Android — c'est une limitation d'Apple, pas de l'application.)

Une fois installée, l'application s'ouvre en plein écran avec sa propre
icône, sans la barre d'adresse du navigateur, et reste utilisable même sans
connexion internet pour l'interface elle-même (les données suivent les
règles habituelles : localStorage en mode local, synchronisation en mode
connecté).

**Fichiers ajoutés pour cela :** `manifest.json`, `sw.js` (service worker),
et les icônes `icon-192.png`, `icon-512.png`, `icon-512-maskable.png`,
`apple-touch-icon.png`, `favicon-32.png` — à héberger avec les autres
fichiers, à la racine, sans rien renommer.

## Déploiement sur GitHub Pages

1. Mettez les 4 fichiers (`index.html`, `style.css`, `app.js`, `config.js`) —
   et `supabase-schema.sql` si vous voulez le garder dans le dépôt — à la
   racine de votre dépôt GitHub.
2. Allez dans **Settings → Pages** du dépôt.
3. Source : branche `main`, dossier `/ (root)`.
4. Enregistrez. En 1-2 minutes, le site est en ligne sur
   `votre-identifiant.github.io/nom-du-depot`.

Aucune compilation, aucun `npm install` nécessaire.

## ⚠️ Correctif critique (si votre badge restait bloqué sur "Local")

Une erreur dans une version précédente empêchait `config.js` d'être
correctement pris en compte par l'application, **même avec une URL et une
clé Supabase valides** : le badge restait alors bloqué sur "Local" quoi que
vous fassiez. C'est corrigé. Si vous avez déjà rempli `config.js`
auparavant sans succès, il n'y a rien à changer dans vos valeurs — il suffit
de remplacer ce fichier `config.js` (et `app.js`) par les nouvelles versions
fournies ici, puis de recharger l'application (avec un rechargement forcé /
navigation privée pour éviter le cache du navigateur).

## Corrections de conformité au cahier des charges (dernière mise à jour)

**12 écarts corrigés suite à un audit détaillé des sections 10 à 28 :**

1. Champ "motif" ajouté aux Entrées de stock (déjà présent pour les Sorties)
2. Workflow sortie chantier complet : validation → bon de sortie émis → confirmation de réception par le chantier (au lieu d'une seule étape)
3. Consommations chantier : distinction livré / consommé / retourné / restant sur chantier (nouvelle possibilité de déclarer une consommation)
4. Champ "adresse" ajouté à la fiche fournisseur
5. Réception marchandises : prix unitaire modifiable par ligne + champ observations
6. **Nouveau module Pertes** dédié (casse, détérioration, vol, péremption, erreur d'inventaire, perte chantier) avec validation obligatoire du responsable au-delà de 50 000 FCFA
7. Inventaire filtrable par catégorie et par matériau (en plus du dépôt)
8. Notifications automatiques étendues : nouvelle demande, demande validée, commande reçue, facture en attente, inventaire à effectuer (dépôt non inventorié depuis 30 jours)
9. Le Responsable chantier peut désormais confirmer la réception de ses livraisons
10. Journal d'activité enrichi : les mouvements de stock affichent matériau, quantité, magasin et destination
11. **Nouveau Rapport financier** (achats, ventes, valeur du stock, coûts par chantier)
12. **Export PDF et Excel** réintroduits (en plus du CSV), avec une **barre de filtres complète** (période, magasin, chantier, catégorie, matériau, fournisseur, utilisateur, type de mouvement)

Un bug de fond a aussi été corrigé au passage : plusieurs filtres et formulaires
(recherche matériaux, filtres de rapports, lignes de devis/commandes) ne se
mettaient pas à jour correctement à cause d'une variable JavaScript mal
déclarée — c'est réparé, testé avec de vraies interactions DOM (et non plus
un test qui pouvait donner un faux résultat positif).

**Corrections précédentes (toujours actives) :**
- **Inventaire** : chaque écart détecté génère un vrai mouvement d'ajustement
  tracé dans l'historique (jamais de modification silencieuse du stock).
- **Unités et conversions** : configurables par l'administrateur depuis
  Paramètres (ex : 1 tonne = 1000 kg).
- **Fiche matériau complétée** : sous-catégorie, description et emplacement.
- **Photo des matériaux** : upload direct depuis la fiche matériau — stockée
  sur Supabase Storage en mode connecté, ou en local (base64) hors-ligne.
- **Hiérarchie des dépôts** : un dépôt peut être rattaché à un dépôt parent,
  affiché en arborescence.

Si vous aviez déjà exécuté une version précédente de `supabase-schema.sql`,
**exécutez à nouveau tout le fichier** : il contient les migrations
nécessaires (nouvelles colonnes, nouvelles tables, bucket de stockage) sans
supprimer aucune donnée existante.

## Fonctionnalités incluses (Phase 1 du cahier des charges)

- Authentification par rôles avec permissions granulaires
- Tableau de bord (KPIs incluant Achats du mois, alertes de stock, 3 graphiques : évolution du stock, entrées/sorties/ajustements, consommation par chantier)
- Matériaux (fiche complète, QR Code téléchargeable)
- Catégories, Dépôts/magasins, Fournisseurs
- Entrées, Sorties, Transferts de stock (mise à jour automatique des quantités)
- Inventaire (théorique vs physique, écarts)
- Chantiers : Liste, Besoins, Affectations, Consommations, Coûts (pages dédiées)
- Demandes de matériaux avec workflow de validation
- Demandes d'achat, bons de commande, réceptions de marchandises, factures fournisseurs
- **Ventes : Clients, Devis, Commandes, Factures** — devis brouillon → envoyé → accepté, conversion en commande, livraison (sortie de stock automatique), facturation et suivi des paiements
- Rapports exportables en CSV
- Notifications automatiques (stock faible, rupture)
- Journal d'activité (traçabilité complète)
- Gestion des utilisateurs et matrice des permissions

## Prochaines évolutions possibles

- Authentification Supabase native (comptes réels, sécurité renforcée)
- Ventes et facturation client
- Notifications WhatsApp / SMS
- Application mobile
