/* =============================================================================
   CONFIGURATION — SAHEL BTP
   =============================================================================
   Renseignez ici l'URL et la clé publique ("anon key") de votre projet
   Supabase pour que l'application devienne DYNAMIQUE : les données seront
   stockées en ligne et partagées entre tous les appareils / utilisateurs,
   au lieu de rester enfermées dans le navigateur d'une seule personne.

   Comment obtenir ces informations :
   1. Créez un compte gratuit sur https://supabase.com
   2. Créez un nouveau projet
   3. Dans l'éditeur SQL du projet, exécutez le contenu du fichier
      "supabase-schema.sql" fourni avec cette application
   4. Allez dans Project Settings → API
   5. Copiez "Project URL" et la clé "anon public" ci-dessous

   Tant que ces deux valeurs restent vides (""), l'application continue de
   fonctionner normalement, mais en mode local : chaque navigateur garde ses
   propres données (comme un brouillon). Dès que vous les renseignez,
   l'application bascule automatiquement en mode connecté.
   ========================================================================= */

window.CONFIG = {
  SUPABASE_URL: "",
  SUPABASE_ANON_KEY: "",
};
