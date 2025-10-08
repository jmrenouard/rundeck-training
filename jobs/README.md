# Générateur de Jobs Rundeck

Cet outil est une application web monopage conçue pour simplifier la création de définitions de jobs Rundeck au format YAML. Il permet aux utilisateurs de construire des workflows complexes de manière interactive, sans avoir à écrire manuellement du YAML.

## Fonctionnalités

- **Interface Intuitive** : Construisez des jobs en remplissant des champs de formulaire pour les détails du job, les options, et les étapes du workflow.
- **Types d'Étapes Multiples** : Support pour les types d'étapes les plus courants, y compris :
    - `exec` (commande simple)
    - `script` (script intégré)
    - `jobref` (référence à un autre job)
    - `scriptfile` (fichier de script sur le serveur)
    - `scripturl` (script depuis une URL)
- **Importation de YAML** : Collez un YAML de job existant pour pré-remplir le formulaire, ce qui facilite la modification de jobs existants.
- **Génération en Temps Réel** : Le code YAML est généré et mis à jour en temps réel à mesure que vous modifiez le formulaire.
- **Internationalisation** : L'interface est disponible en Français et en Anglais.
- **Copie Facile** : Copiez le YAML généré dans votre presse-papiers en un seul clic.

## Utilisation

1.  Ouvrez le fichier `index.html` dans un navigateur web.
2.  Utilisez les sections du formulaire pour définir les propriétés de votre job.
3.  Ajoutez des options de job si nécessaire.
4.  Construisez votre workflow en ajoutant des étapes. Configurez chaque étape avec ses paramètres spécifiques.
5.  Si vous avez un job existant, utilisez la fonction d'importation pour coller le YAML et le modifier.
6.  Le YAML généré apparaîtra sur le côté droit.
7.  Cliquez sur le bouton "Copier" pour copier le YAML dans votre presse-papiers.
8.  Collez le YAML dans un fichier `.yml` dans votre projet Rundeck.

Ce générateur est particulièrement utile pour créer rapidement des squelettes de jobs ou pour les utilisateurs moins familiers avec la syntaxe YAML de Rundeck.