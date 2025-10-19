# Générateur de Fichier de Propriétés Rundeck

Cet outil permet de générer des fichiers `realm.properties` pour Rundeck. Il gère les utilisateurs, les groupes et l'encodage des mots de passe.

## Fonctionnalités

- Ajout, suppression et modification d'utilisateurs.
- Gestion des groupes pour chaque utilisateur.
- Encodage des mots de passe en `plaintext`, `OBF` (obfuscation Jetty) et `MD5`.
- Importation de fichiers `realm.properties` existants.
- Interface en Français et en Anglais.

## Utilisation

1. Ouvrez le fichier `index.html` dans votre navigateur.
2. Ajoutez ou importez des utilisateurs.
3. Remplissez les informations pour chaque utilisateur (nom d'utilisateur, mot de passe, groupes).
4. Sélectionnez le type d'encodage pour le mot de passe.
5. Le contenu du fichier `realm.properties` est généré automatiquement.
6. Copiez le contenu généré et collez-le dans votre fichier `realm.properties` sur votre serveur Rundeck.

---

# Rundeck Property File Generator

This tool allows you to generate `realm.properties` files for Rundeck. It handles users, groups, and password encoding.

## Features

- Add, remove, and edit users.
- Manage groups for each user.
- Password encoding in `plaintext`, `OBF` (Jetty obfuscation), and `MD5`.
- Import existing `realm.properties` files.
- Interface in French and English.

## Usage

1. Open the `index.html` file in your browser.
2. Add or import users.
3. Fill in the information for each user (username, password, groups).
4. Select the encoding type for the password.
5. The content of the `realm.properties` file is generated automatically.
6. Copy the generated content and paste it into your `realm.properties` file on your Rundeck server.