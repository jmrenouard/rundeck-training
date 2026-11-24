# Rundeck Property File Generator

> **Language:** English | [Français](README.md)

This browser-based tool generates `realm.properties` files for Rundeck, managing users, groups, and password hashing.

## Features

- Add, remove, and edit users.
- Manage group memberships per user.
- Hash or format passwords as `plaintext`, `OBF` (Jetty obfuscation), `MD5`, or `BCRYPT` (`bcrypt.min.js`).
- Import existing `realm.properties` entries.
- Interactive interface available in English and French.

## Usage

1. Open `index.html` in your web browser.
2. Add users manually or import an existing `realm.properties` snippet.
3. Fill in each user's username, password, and group list.
4. Select the desired password encoding method.
5. Copy the generated output into your Rundeck server's `realm.properties` file.
