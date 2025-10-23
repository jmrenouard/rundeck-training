# Exécution de Nœuds Windows avec Ansible et Rundeck

Connecter Ansible ou Rundeck à des machines Windows est un grand classique et une étape indispensable. La principale différence avec Linux/macOS, c'est que Windows n'utilise pas **SSH** nativement (même si c'est possible aujourd'hui). Le protocole standard pour l'administration à distance sous Windows s'appelle **WinRM**.

C'est parti \! Nous allons décortiquer cela pas à pas. 👨‍🏫

-----

## Le Concept Clé : WinRM (Windows Remote Management)

Pensez à **WinRM** comme au "SSH du monde Windows". C'est le service qui nous permet d'envoyer des commandes (PowerShell, CMD) à une machine Windows distante et de recevoir les résultats.

  * Il utilise le protocole **SOAP** (un standard web).
  * Il écoute généralement sur deux ports :
      * **5985** (HTTP) : Non chiffré. À n'utiliser *que* dans des réseaux de test ultra-sécurisés.
      * **5986** (HTTPS) : Chiffré. C'est la cible que vous devez *toujours* viser en production.

Notre objectif est donc double :

1.  Configurer le serveur Windows pour qu'il accepte les connexions WinRM.
2.  Configurer notre outil (Ansible ou Rundeck) pour qu'il parle ce protocole.

-----

## Étape 1 : Prérequis et Configuration du Nœud Windows

C'est l'étape la plus importante. Si la machine Windows n'est pas prête, rien ne fonctionnera. Voici la checklist complète des prérequis.

### 1\. Version de PowerShell

Assurez-vous d'avoir **PowerShell 3.0 ou une version ultérieure**.
Sur tous les systèmes modernes (Windows Server 2012 R2, 2016, 2019, 2022, Windows 10/11), c'est déjà le cas.

### 2\. Le Service WinRM

Le service "Windows Remote Management (WS-Management)" doit être en cours d'exécution.

### 3\. Configuration de l'Écoute (Listener) WinRM

C'est ici que 90% des problèmes surviennent. La machine Windows doit être configurée pour accepter les connexions distantes.

#### La Méthode Facile (Recommandée par Ansible)

Ansible fournit un script PowerShell merveilleux qui fait tout le travail pour vous. C'est la méthode que je vous conseille pour démarrer rapidement.

1.  Téléchargez ce script depuis le dépôt officiel d'Ansible : [ConfigureRemotingForAnsible.ps1](https://www.google.com/search?q=https://github.com/ansible/ansible/blob/devel/examples/scripts/ConfigureRemotingForAnsible.ps1)
2.  Transférez-le sur votre serveur Windows.
3.  Ouvrez une console **PowerShell en tant qu'Administrateur**.
4.  Exécutez-le.

**Exemple d'exécution (pour un certificat auto-signé HTTPS) :**

```powershell
# Assurez-vous que l'exécution des scripts est autorisée pour cette session
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force

# Exécutez le script. 
# -Force pour créer un certificat auto-signé (idéal pour les tests)
# -EnableCredSSP pour permettre une authentification plus avancée (optionnel mais souvent utile)
.\ConfigureRemotingForAnsible.ps1 -Force -EnableCredSSP

# Si vous voulez juste du HTTP (NON RECOMMANDÉ HORS TEST)
# .\ConfigureRemotingForAnsible.ps1 -Force -SkipNetworkProfileCheck
```

Ce script va automatiquement :

  * Configurer le service WinRM.
  * Créer un **listener HTTPS** sur le port 5986.
  * Générer un **certificat auto-signé** (pour les tests) ou vous laisser en spécifier un.
  * Ouvrir les **ports 5985/5986** dans le Pare-feu Windows.
  * Activer l'authentification `Basic` (nécessaire pour Ansible si on n'utilise pas Kerberos).

#### La Méthode Manuelle (Pour comprendre ce qu'il se passe)

Si vous voulez le faire à la main, voici les commandes PowerShell équivalentes :

```powershell
# 1. Commande de base pour activer WinRM (crée un listener HTTP)
Enable-PSRemoting -force

# 2. Activer l'authentification "Basic" (nécessaire pour Ansible avec login/pass sur HTTPS)
# Ansible ne peut pas utiliser l'authentification NTLM par défaut avec un simple mot de passe.
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true

# 3. (OPTIONNEL) Autoriser le trafic non chiffré (HTTP) - DANGEREUX
# À n'utiliser que si vous ne pouvez VRAIMENT pas faire de HTTPS
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# 4. Ouvrir le pare-feu
New-NetFirewallRule -Name "WinRM-HTTP" -DisplayName "WinRM-HTTP" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5985 -Protocol TCP
New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM-HTTPS" -Enabled True -Profile Any -Action Allow -Direction Inbound -LocalPort 5986 -Protocol TCP
```

*Note : La configuration manuelle d'un certificat HTTPS est plus complexe, c'est pourquoi le script Ansible est si pratique.*

### 4\. Authentification

Vous aurez besoin d'un **compte utilisateur local (ou de domaine)** sur le serveur Windows qui a les **droits d'administration**. C'est ce compte que Ansible/Rundeck utilisera pour se connecter.

-----

## Étape 2 : Connexion avec Ansible

Maintenant que notre serveur Windows est prêt, configurons Ansible (sur notre machine de contrôle Linux/macOS) pour lui parler.

### 1\. Prérequis (Machine de Contrôle Ansible)

Ansible a besoin d'une bibliothèque Python pour parler WinRM.

```bash
# Installez le module Python requis
pip install pywinrm
```

### 2\. Configuration de l'Inventaire

C'est la partie la plus importante. Vous devez dire à Ansible que ce nœud n'est pas un nœud SSH.

**Exemple de fichier `inventory.ini` :**

```ini
[windows]
# L'adresse IP ou le FQDN de votre serveur Windows
win-server-01.example.com

[windows:vars]
# Indique à Ansible d'utiliser WinRM au lieu de SSH
ansible_connection=winrm

# L'utilisateur (local ou domaine)
ansible_user=AdminRundeck

# Le mot de passe (Mieux vaut utiliser Ansible Vault, mais ceci est pour l'exemple)
ansible_password=MonMotDePasseTresSecurise123!

# Le port à utiliser (5986 pour HTTPS, 5985 pour HTTP)
ansible_port=5986

# --- Options de transport et de sécurité ---

# L'astuce pour HTTPS : quel protocole d'authentification utiliser ?
# 'basic' : simple login/pass (nécessite HTTPS et l'activation vue à l'étape 1)
# 'ntlm' : authentification Windows (plus complexe, souvent pour le domaine)
# 'kerberos' : authentification de domaine (la plus sécurisée, la plus complexe)
# 'credssp' : si vous avez besoin de "délégation" (ex: se connecter à une 2e machine)
ansible_winrm_transport=basic

# SI vous utilisez un certificat AUTO-SIGNÉ (comme celui du script)
# vous devez dire à Ansible d'ignorer la validation.
# En production, vous devez installer un VRAI certificat et supprimer cette ligne.
ansible_winrm_server_cert_validation=ignore
```

### 3\. Test de Connexion (Playbook)

Créons un playbook simple pour vérifier que tout fonctionne. Ansible utilise des modules spécifiques pour Windows (commençant par `win_`). Vous ne pouvez pas utiliser les modules `shell` ou `command` classiques.

**Exemple de playbook `test_windows.yml` :**

```yaml
---
- name: Tester la connexion WinRM à Windows
  hosts: windows
  gather_facts: false # On désactive la collecte de faits pour ce premier test

  tasks:
    - name: Exécuter un "ping" WinRM
      ansible.windows.win_ping:
      register: ping_result

    - name: Afficher le résultat
      debug:
        var: ping_result

    - name: Exécuter une commande PowerShell simple
      ansible.windows.win_shell: Get-Process -Name "winrm"
      register: ps_result

    - name: Afficher le résultat de PowerShell
      debug:
        var: ps_result.stdout_lines
```

**Exécutez-le :**

```bash
ansible-playbook -i inventory.ini test_windows.yml
```

Si vous voyez `pong` dans la sortie, vous avez réussi \! 🎉

-----

## Étape 3 : Connexion avec Rundeck

Rundeck a deux façons principales de gérer les nœuds Windows.

### Option A : Utiliser le Plugin Ansible (Recommandé)

Si vous utilisez déjà Ansible, c'est la meilleure solution.

1.  **Configurez Rundeck** pour qu'il utilise votre inventaire Ansible comme **source de nœuds** (Node Source).
2.  **Configurez l'exécuteur de nœud (Node Executor)** du projet pour qu'il soit "Ansible".
3.  **Rundeck délègue tout à Ansible**. Il lira votre inventaire `inventory.ini` (avec toutes les variables `ansible_connection=winrm`...) et utilisera `ansible-playbook` en arrière-plan pour exécuter les commandes.

**Avantage :** Vous n'avez à configurer la connexion WinRM qu'une seule fois (dans l'inventaire Ansible).

### Option B : Utiliser un Plugin WinRM pour Rundeck (Direct)

Rundeck peut aussi parler WinRM directement (sans Ansible) grâce à un plugin. Le plus courant est le **"WinRM Node Executor"** (souvent basé sur `pywinrm`, le même que celui d'Ansible).

Vous devrez définir votre nœud (par exemple dans le fichier `resources.yml` de votre projet) en spécifiant les attributs WinRM.

**Exemple de définition de nœud Windows dans `resources.yml` :**

```yaml
# /var/rundeck/projects/MonProjet/etc/resources.yml
win-server-01:
  # Nom du nœud dans l'interface Rundeck
  nodename: win-server-01
  
  # Infos de base
  hostname: win-server-01.example.com
  osFamily: windows
  osName: Windows Server 2019
  username: AdminRundeck
  
  # --- Configuration de l'exécuteur WinRM ---
  
  # Spécifie quel plugin utiliser pour ce nœud
  # (le nom exact peut varier selon le plugin installé)
  node-executor: winrm # ou "py-winrm", etc.
  
  # Spécifie le protocole (http ou https)
  winrm-protocol: https
  
  # Spécifie le port (5986 pour https)
  winrm-port: 5986
  
  # Spécifie le transport d'authentification
  winrm-auth-type: basic
  
  # Ignore la validation du certificat (pour les certificats auto-signés)
  winrm-cert-validation: ignore
  
  # --- Gestion du mot de passe (SÉCURISÉ) ---
  # NE JAMAIS METTRE LE MOT DE PASSE EN CLAIR ICI
  # Utilisez le Key Storage de Rundeck
  winrm-password-storage-path: keys/windows/admin.password
```

Dans cet exemple, `keys/windows/admin.password` fait référence à une clé que vous avez stockée en toute sécurité dans le **Key Storage** de Rundeck.

-----

## Résumé et Encouragements

Comme vous pouvez le voir, la connexion à Windows demande un peu plus de préparation initiale que pour Linux.

  * **Côté Windows :** Le plus important est de **configurer WinRM** (idéalement avec le script Ansible) pour qu'il écoute en **HTTPS (5986)** et accepte l'authentification que vous allez utiliser (souvent `Basic` pour démarrer).
  * **Côté Ansible/Rundeck :** Il faut "juste" spécifier les bonnes variables de connexion (`ansible_connection: winrm`, le port, le transport, et l'option `ignore` pour les certificats de test).
