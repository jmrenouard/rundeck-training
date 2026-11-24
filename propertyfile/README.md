# Générateur de Fichier de Propriétés Rundeck

> **Langue :** Français | [English](README.en.md)

Cet outil web permet de générer des fichiers `realm.properties` pour Rundeck. Il gère les utilisateurs, les groupes et l'encodage des mots de passe.

## Fonctionnalités

- Ajout, suppression et modification d'utilisateurs.
- Gestion des groupes pour chaque utilisateur.
- Encodage des mots de passe en `plaintext`, `OBF` (obfuscation Jetty), `MD5` et `BCRYPT` (`bcrypt.min.js`).
- Importation de fichiers `realm.properties` existants.
- Interface disponible en français et en anglais.

## Utilisation

1. Ouvrez le fichier `index.html` dans votre navigateur.
2. Ajoutez ou importez des utilisateurs.
3. Remplissez les informations pour chaque utilisateur (nom d'utilisateur, mot de passe, groupes).
4. Sélectionnez le type d'encodage pour le mot de passe.
5. Copiez le contenu généré automatiquement et collez-le dans votre fichier `realm.properties` sur votre serveur Rundeck.
