# Configuration Supabase - Portail Entreprise Flashback Fa

## Étape 1 : Configuration de la Base de Données

### 1.1 Créer les Tables
Connectez-vous à votre dashboard Supabase : https://dutvmjnhnrpqoztftzgd.supabase.co

Dans l'éditeur SQL, exécutez le contenu du fichier `/app/supabase_schema.sql`

### 1.2 Configurer les Politiques RLS
Exécutez ensuite le contenu du fichier `/app/supabase_rls.sql`

## Étape 2 : Configuration Discord OAuth

### 2.1 Dans Discord Developer Portal
1. Allez sur https://discord.com/developers/applications
2. Créez une nouvelle application ou sélectionnez une existante
3. Dans "OAuth2" → "General" :
   - **Client ID** : Notez cet ID
   - **Client Secret** : Notez ce secret
   - **Redirects** : Ajoutez `https://dutvmjnhnrpqoztftzgd.supabase.co/auth/v1/callback`

### 2.2 Dans Supabase Dashboard
1. Allez dans "Authentication" → "Providers"
2. Activez "Discord"
3. Entrez votre **Client ID** et **Client Secret** Discord
4. Sauvegardez

## Étape 3 : Configuration des Rôles Discord

### 3.1 Récupérer les IDs des Rôles
Dans Discord (mode développeur activé) :
1. Clic droit sur chaque rôle → "Copier l'ID"
2. Notez les IDs pour : staff, patron, co-patron, dot, employe

### 3.2 Mettre à jour la Configuration
Les IDs seront intégrés dans l'application automatiquement.

## Étape 4 : Variables à Fournir

Une fois la configuration terminée, veuillez me fournir :

1. **Discord Application Client ID** : `123456789012345678`
2. **Guild ID** (ID du serveur Discord) : `1404608015230832742` (déjà configuré)
3. **Role IDs** :
   - Staff : `role_id_staff`
   - Patron : `role_id_patron`
   - Co-Patron : `role_id_co_patron`
   - DOT : `role_id_dot`
   - Employe : `role_id_employe`

## Étape 5 : Test de Connexion

Une fois tout configuré, l'application pourra :
- ✅ Authentifier les utilisateurs via Discord
- ✅ Récupérer automatiquement leurs rôles
- ✅ Appliquer les permissions appropriées
- ✅ Stocker les données dans Supabase

---

**Prêt ?** Exécutez d'abord les scripts SQL, puis configurez Discord OAuth. Je vous aiderai ensuite avec les fonctions Edge et les tests finaux.