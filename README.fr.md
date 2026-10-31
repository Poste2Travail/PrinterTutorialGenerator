# PrinterTutorialGenerator

**Français** | [English](README.md)

Générateur de tutoriels personnalisés pour l'installation des imprimantes réseau, basé sur le **nom** de l'imprimante et son **emplacement**. Un outil simple pour les équipes workplace, déployable en local sur un serveur IIS.

## Sommaire

1. [Fonctionnement](#1-fonctionnement)
2. [Prérequis](#2-prérequis)
3. [Installation du projet](#3-installation-du-projet)
4. [Lister automatiquement les imprimantes](#4-lister-automatiquement-les-imprimantes)
5. [Publier les tutoriels sur IIS (côté technicien)](#5-publier-les-tutoriels-sur-iis-côté-technicien)
6. [Site utilisateur](#6-site-utilisateur)
7. [Tutoriel : GPO d'installation sans élévation de droits](#7-tutoriel--gpo-dinstallation-sans-élévation-de-droits)
8. [Tutoriel : correctif PrintNightmare et durcissement Point and Print (GPO sur site)](#8-tutoriel--correctif-printnightmare-et-durcissement-point-and-print-gpo-sur-site)
9. [Tutoriel : durcissement PrintNightmare avec Microsoft Intune](#9-tutoriel--durcissement-printnightmare-avec-microsoft-intune)
10. [Tutoriel : durcissement PrintNightmare avec VMware Workspace ONE UEM](#10-tutoriel--durcissement-printnightmare-avec-vmware-workspace-one-uem)
11. [Tutoriel : serveur Windows pour clients macOS et Linux](#11-tutoriel--serveur-windows-pour-clients-macos-et-linux)
12. [Structure du dépôt](#12-structure-du-dépôt)
13. [Format de données `printers.json`](#13-format-de-données-printersjson)
14. [Dépannage](#14-dépannage)
15. [Licence](#15-licence)

---

## 1. Fonctionnement

| Composant | Rôle |
|---|---|
| `Export-PrinterList.ps1` | Interroge un serveur d'impression Windows et génère `printers.json`. |
| `editeur-imprimantes.html` | Éditeur pour technicien : ajouter, modifier, réorganiser les imprimantes, personnaliser l'en-tête et le bas de page. |
| `printers.json` | Source unique de vérité, lue par le site utilisateur. |
| `index.html` | Site utilisateur : recherche d'une imprimante, puis tutoriel d'installation pour Windows, macOS ou Linux. |

Un utilisateur ouvre le site sur le réseau local, retrouve son imprimante par nom ou emplacement, et suit les étapes correspondant à son système. Le serveur et la file d'impression sont pré-remplis et copiables en un clic.

## 2. Prérequis

**Serveur d'impression Windows**
- Windows Server 2012 R2 ou supérieur, rôle *Services d'impression et de numérisation* installé.
- Imprimantes partagées (partage activé sur chaque file d'impression).
- Module PowerShell `PrintManagement` disponible (inclus par défaut).
- Compte de service en lecture seule sur le serveur d'impression pour l'export.

**Serveur de publication**
- Windows Server avec le rôle **IIS**, en HTTP sur le réseau interne uniquement.
- Droits d'écriture sur le dossier de publication pour le technicien qui met à jour `printers.json`.

**Poste technicien**
- Un navigateur récent (Edge, Chrome, Firefox).
- PowerShell 5.1 ou supérieur pour l'export.

**Dépôt**
- Git pour cloner le projet.
- Aucune dépendance npm/pip : le projet est en HTML, CSS, JavaScript et PowerShell.

## 3. Installation du projet

```powershell
git clone https://github.com/Poste2Travail/PrinterTutorialGenerator.git
cd PrinterTutorialGenerator
```

Copier les fichiers du projet sur le serveur IIS, par exemple dans `C:\inetpub\wwwroot\printers\`.

Vérifier que le fichier de données est servi : ouvrir `http://<serveur>/printers/printers.json` dans un navigateur. Il doit s'afficher sans erreur 404.

## 4. Lister automatiquement les imprimantes

Le script `Export-PrinterList.ps1` lit les files d'impression partagées du serveur d'impression et produit `printers.json`. Il ne modifie jamais le serveur.

**Exemple d'exécution**

```powershell
.\Export-PrinterList.ps1 `
    -Server PRTSRV01.exemple.local `
    -OutFile C:\inetpub\wwwroot\printers\printers.json `
    -MappingFile .\mapping.csv
```

**Fichier de correspondance optionnel `mapping.csv`** (séparateur `;`) pour donner un emplacement lisible à chaque file d'impression :

```csv
queue;location
IMP-1R-01;1er étage - Entrée principale
IMP-3C-01;3ème étage - Couloir C01
```

Sans ce fichier, l'emplacement est repris de la propriété `Location` de Windows, ou marqué `À compléter`. Compléter ensuite via l'éditeur.

**Planification** : pour une liste à jour chaque nuit, créer une tâche planifiée (`taskschd.msc`) exécutant le script sous un compte de service, déclenchée chaque jour à 02h00.

## 5. Publier les tutoriels sur IIS (côté technicien)

1. Créer un site ou une application IIS nommée `printers`, liée à `C:\inetpub\wwwroot\printers`.
2. Restreindre l'accès au réseau interne (authentification anonyme activée, restrictions d'adresses IP si nécessaire).
3. Vérifier le type MIME `.json` : `application/json` (présent par défaut sur IIS récent).
4. Ouvrir `editeur-imprimantes.html`, modifier la liste, cliquer sur **Télécharger JSON** et remplacer `printers.json` sur le serveur.

Les utilisateurs voient les modifications au rechargement de la page.

## 6. Site utilisateur

`index.html` est la page ouverte par les utilisateurs. Elle doit se trouver **dans le même dossier** que `printers.json` :

```
C:\inetpub\wwwroot\printers\
├── index.html        ← site utilisateur (ce fichier)
└── printers.json     ← généré par Export-PrinterList.ps1 ou l'éditeur
```

L'adresse communiquée aux utilisateurs est donc `http://<serveur>/printers/`.

Ce que fait le site :
- Bascule FR / EN, mémorisée dans le navigateur. La langue est détectée au premier accès.
- Recherche instantanée par nom, emplacement ou file d'impression.
- Pour l'imprimante choisie, un tutoriel pas à pas pour **Windows**, **macOS** et **Linux**, avec le chemin du serveur ou la commande prêts à copier.
- En-tête, sous-titre et bas de page (contact support, horaires, portail) viennent du bloc `config` de `printers.json`.

Pour modifier la mise en page ou les textes, éditer `index.html` : les traductions se trouvent dans l'objet `T` en haut du script.

## 7. Tutoriel : GPO d'installation sans élévation de droits

Objectif : permettre aux utilisateurs standard d'installer les imprimantes **et leurs pilotes** depuis des serveurs d'impression approuvés, sans invite UAC et sans droits administrateurs locaux, en conservant la base de durcissement de la section 8.

La base de durcissement n'est jamais assouplie pour y parvenir : les pilotes ne viennent que de **serveurs approuvés**, l'installation des pilotes reste **réservée aux administrateurs**, et les **invites d'élévation sont conservées**.

### 7.1 Principe

Depuis la mise à jour de juillet 2021 (CVE-2021-34527), Windows réserve l'installation des pilotes d'impression aux administrateurs. Deux mécanismes entrent en jeu, qui ne sont pas équivalents :

- **Restriction des serveurs** (*Restrictions Point and Print*) : les pilotes ne peuvent venir que des FQDN listés.
- **Restriction des pilotes** (*Limiter l'installation des pilotes d'impression aux administrateurs*) : qui peut installer un pilote.

La méthode recommandée pour permettre aux utilisateurs standard d'installer des imprimantes est le **Package Point and Print** : pilotes signés et packagés, servis uniquement par des serveurs approuvés. Qu'un utilisateur standard puisse installer un pilote packagé tout en gardant la restriction administrateur dépend de la version de Windows : **à valider en laboratoire d'abord** (7.6). Si cela ne fonctionne pas, ne pas désactiver la restriction globalement ; suivre le processus d'exception de la section 8.3.

### 7.2 Créer la GPO

1. Ouvrir la *Gestion de stratégie de groupe* (`gpmc.msc`).
2. Créer une GPO `GPO - Imprimantes Utilisateurs` et la lier à l'unité d'organisation contenant les postes (pas les utilisateurs).
3. Éditer la GPO, puis aller dans :
   `Configuration ordinateur > Stratégies > Modèles d'administration > Imprimantes`

### 7.3 Paramètres à configurer

| Paramètre | Valeur | Effet |
|---|---|---|
| **Restrictions Point and Print** | Activé | Active les restrictions de serveurs. |
| *Les utilisateurs ne peuvent pousser des pilotes que vers ces serveurs* | Activé, `PRTSRV01.exemple.local;PRTSRV02.exemple.local` | Seuls les serveurs listés peuvent fournir des pilotes. Utiliser les FQDN, pas les noms courts. |
| *Lors de l'installation de pilotes pour une nouvelle connexion* | **Afficher l'avertissement et l'invite d'élévation** | Conserve l'invite de sécurité. |
| *Lors de la mise à jour de pilotes pour une connexion existante* | **Afficher l'avertissement et l'invite d'élévation** | Conserve l'invite de sécurité. |
| **Package Point and Print - Serveurs approuvés** | Activé, même liste de FQDN | Limite les pilotes packagés aux serveurs approuvés. |
| **Limiter l'installation des pilotes d'impression aux administrateurs** | Activé | Base de référence. À désactiver uniquement via le processus d'exception de 8.3. |

Chemins :
- `Configuration ordinateur > Stratégies > Modèles d'administration > Imprimantes > Restrictions Point and Print`
- `Configuration ordinateur > Stratégies > Modèles d'administration > Imprimantes > Package Point and Print - Serveurs approuvés`

> Ne pas activer *Ne pas afficher d'avertissement ni d'invite d'élévation*. Ce paramètre affaiblit la protection et ne fait pas partie de la base de ce projet.

### 7.4 Clés registre équivalentes (sans GPMC)

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers]
"RestrictDriverInstallationToAdministrators"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint]
"Restricted"=dword:00000001
"TrustedServers"=dword:00000001
"ServerList"="PRTSRV01.exemple.local;PRTSRV02.exemple.local"
"NoWarningNoElevationOnInstall"=dword:00000000
"UpdatePromptSettings"=dword:00000000
```

Sur un parc géré, définir ces valeurs par la GPO et non à la main. La forme registre sert de référence et pour la vérification de la section 8.4.

### 7.5 Package Point and Print (recommandé)

1. Sur chaque serveur d'impression approuvé, ajouter les pilotes signés à la file d'impression via *Gestion d'impression* (`printmanagement.msc`).
2. Vérifier que les pilotes sont signés par l'éditeur (WHQL ou signature Microsoft).
3. Activer les paramètres de 7.3, y compris *Package Point and Print - Serveurs approuvés*.
4. Tester sur un poste de référence avec un compte standard : *Ajouter une imprimante > L'imprimante que je veux n'est pas répertoriée > Sélectionner une imprimante partagée par nom*, puis saisir `\\PRTSRV01.exemple.local\IMP-1R-01`.

### 7.6 Vérification

```powershell
# Sur le poste, avec un compte standard
gpresult /r | Select-String "Point and Print"
Get-Printer | Select-Object Name, DriverName, PortName
```

Une installation réussie depuis un serveur approuvé doit fonctionner **sans** invite UAC. Si une invite apparaît, vérifier l'état avec la commande de la section 8.4 avant toute modification.

## 8. Tutoriel : correctif PrintNightmare et durcissement Point and Print (GPO sur site)

Le correctif **PrintNightmare** (CVE-2021-34527, CVE-2021-1675) doit rester actif. Le durcissement Point and Print ci-dessous est ce qui le rend efficace en pratique : le correctif limite **qui** installe les pilotes, la liste blanche de serveurs limite **d'où** ils viennent. Les deux sont nécessaires.

### 8.1 Base de durcissement

| Contrôle | Valeur | Remarque |
|---|---|---|
| `RestrictDriverInstallationToAdministrators` | `1` | Installation des pilotes réservée aux administrateurs. |
| Restrictions Point and Print | Activé | Restriction de serveurs active. |
| Seuls les serveurs spécifiés (`TrustedServers`) | Activé | Pilotes uniquement depuis les serveurs listés. |
| Serveurs approuvés (`ServerList`) | `PRTSRV01.exemple.local;PRTSRV02.exemple.local` | Toujours des FQDN. |
| Package Point and Print - serveurs approuvés | Activé, même liste | Pilotes packagés uniquement depuis les serveurs approuvés. |
| `NoWarningNoElevationOnInstall` | `0` / Désactivé | Conserver les invites d'élévation. |
| `UpdatePromptSettings` | `0` | Conserver les invites pour les mises à jour de pilotes. |
| Spouleur sur les contrôleurs de domaine | Désactivé | Réduit le risque de coercition (MS-RPRN / PrinterBug). |
| Spouleur sur les systèmes Tier 0 | Désactivé sauf besoin | Ne le garder que si une fonction d'impression est nécessaire. |
| Spouleur sur les postes clients | Activé si nécessaire | Nécessaire à l'impression locale. |
| Serveurs d'impression | Activés, corrigés et durcis | Les maintenir à jour. |

### 8.2 Pourquoi les deux contrôles sont nécessaires

```text
Poste Windows
│
┌───────────┴───────────┐
│                       │
Restriction serveurs    Restriction pilotes
│                       │
PRTSRV01 autorisé       Administrateur requis
PRTSRV02 autorisé       │
│                       │
└───────────┬───────────┘
            │
      File d'impression
```

Ne **pas** remplacer `RestrictDriverInstallationToAdministrators = 1` par la formule « les utilisateurs sont limités à PRTSRV01 ». Ce n'est pas équivalent : la liste de serveurs indique d'où viennent les pilotes, la restriction administrateur indique qui les installe. La combinaison sécurisée est :

1. Uniquement des serveurs approuvés.
2. Installation des pilotes réservée aux administrateurs.
3. Package Point and Print limité aux serveurs approuvés.
4. Invites d'élévation conservées.
5. Spouleur désactivé là où il est inutile.

### 8.3 Processus d'exception

Assouplir `RestrictDriverInstallationToAdministrators` à `0` n'est autorisé que si toutes les conditions suivantes sont réunies :

- Une acceptation écrite du risque est signée par le responsable sécurité.
- Le périmètre est un groupe AD ou Entra ID dédié, par exemple `GRP-DEV-ImprimantesSansElevation`, ne contenant que les postes concernés.
- La liste blanche de serveurs (`TrustedServers` / `ServerList`) reste en place.
- Les événements d'impression sont surveillés (*Journaux des applications et des services > Microsoft > Windows > PrintService*).
- L'exception est réexaminée à chaque cycle de correctifs, ou au moins tous les trois mois.

Ne jamais désactiver globalement les invites d'élévation, et ne jamais accepter « n'importe quel serveur » comme solution de repli.

### 8.4 Vérifier l'état effectif sur chaque poste

```powershell
$Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint'
$Base = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers'

Get-ItemProperty $Base -Name RestrictDriverInstallationToAdministrators -ErrorAction SilentlyContinue |
    Select-Object RestrictDriverInstallationToAdministrators

Get-ItemProperty $Path -ErrorAction SilentlyContinue |
    Select-Object Restricted, TrustedServers, ServerList, NoWarningNoElevationOnInstall, UpdatePromptSettings
```

Valeurs attendues : `RestrictDriverInstallationToAdministrators = 1` (ou l'exception approuvée), `Restricted = 1`, `TrustedServers = 1`, `ServerList` ne contenant que les FQDN approuvés, `NoWarningNoElevationOnInstall = 0`. Une valeur absente signifie que le paramètre n'est pas appliqué : vérifier le lien de la GPO ou le profil de l'appareil.

### 8.5 Service Spouleur d'impression

```powershell
Get-Service Spooler
```

- Sur les contrôleurs de domaine, le Spouleur doit être **Désactivé** et arrêté.
- Sur les systèmes Tier 0, le désactiver sauf si une fonction d'impression est nécessaire.
- Sur les postes clients, le garder en marche si l'impression locale est requise.

### 8.6 Maintenance

- Relancer les contrôles de 8.4 après chaque mise à jour cumulative : une mise à jour de sécurité peut réinitialiser une valeur registre.
- Examiner les journaux PrintService pour détecter des installations de pilotes inattendues.
- Garder la liste des serveurs approuvés alignée sur les serveurs réellement utilisés et sur `printers.json`.

## 9. Tutoriel : durcissement PrintNightmare avec Microsoft Intune

Intune ne peut pas lier une GPO. La même base que la section 8 est déployée via une **stratégie de configuration d'appareil**. Les appareils doivent pouvoir joindre les serveurs d'impression approuvés (sur site, ou via VPN selon l'architecture).

### 9.1 Créer la stratégie

1. Dans le centre d'administration Intune : *Appareils > Windows > Configuration > Créer > Nouvelle stratégie*.
2. Plateforme : **Windows 10 et versions ultérieures**, type de profil : **Catalogue de paramètres**.
3. Dans la catégorie **Imprimantes**, configurer :
   - **Restrictions Point and Print** : Activé
     - *Les utilisateurs ne peuvent pousser des pilotes que vers ces serveurs* : activé, liste `PRTSRV01.exemple.local;PRTSRV02.exemple.local`
     - *Lors de l'installation de pilotes pour une nouvelle connexion* : **Afficher l'avertissement et l'invite d'élévation**
     - *Lors de la mise à jour de pilotes pour une connexion existante* : **Afficher l'avertissement et l'invite d'élévation**
   - **Package Point and Print - Serveurs approuvés** : Activé, même liste
   - **Limiter l'installation des pilotes d'impression aux administrateurs** : **Activé**
4. Affecter la stratégie à un groupe d'**appareils** (pas d'utilisateurs).

> Les intitulés peuvent varier selon la version d'Intune. Rechercher dans le catalogue avec les mots-clés `Point and Print` et `Limiter l'installation`.

### 9.2 Valeurs OMA-URI équivalentes (profil personnalisé, si un paramètre n'est pas exposé)

Vérifier les chemins OMA-URI exacts dans votre locataire avant déploiement.

| Valeur registre | Valeur de base | Remarque |
|---|---|---|
| `RestrictDriverInstallationToAdministrators` (Imprimantes) | `1` | Base. `0` uniquement pour le groupe d'exception approuvé (8.3). |
| `Restricted` (PointAndPrint) | `1` | Active les restrictions Point and Print. |
| `TrustedServers` (PointAndPrint) | `1` | Seuls les serveurs de `ServerList`. |
| `ServerList` (PointAndPrint) | `PRTSRV01.exemple.local;PRTSRV02.exemple.local` | Valeur de type chaîne, FQDN uniquement. |
| `NoWarningNoElevationOnInstall` (PointAndPrint) | `0` | Jamais `1`. |

### 9.3 Groupe d'exception (uniquement si approuvé sous 8.3)

Créer un groupe d'appareils Entra ID dédié, par exemple `GRP-DEV-ImprimantesSansElevation`, ne contenant que les appareils couverts par l'exception. Affecter la valeur assouplie à ce seul groupe. Tous les autres appareils gardent la base.

### 9.4 Vérifier sur l'appareil

Exécuter le contrôle de la section 8.4 sur l'appareil. Puis ouvrir une session en compte standard et installer une imprimante depuis `\\PRTSRV01.exemple.local\IMP-1R-01`. Pour le groupe de base, une invite UAC n'est acceptable que si le pilote n'est pas encore packagé sur le serveur approuvé ; dans ce cas, revenir à 7.5.

## 10. Tutoriel : durcissement PrintNightmare avec VMware Workspace ONE UEM

Workspace ONE UEM (anciennement AirWatch) gère les appareils Windows par profils et, pour les paramètres sans charge native, par **Paramètres personnalisés** (OMA-URI / SyncML) ou par **Scripts**. Les valeurs sont la base de la section 8. Vérifier les intitulés selon votre version de console.

### 10.1 Option A (recommandée) : profil Paramètres personnalisés

1. Dans la console Workspace ONE UEM : *Appareils > Profils et ressources > Profils > Ajouter > Ajouter un profil > Windows > Windows Desktop > Paramètres personnalisés*.
2. Coller un bloc SyncML par valeur. Exemple pour la restriction administrateur :

```xml
<Replace>
  <CmdID>1</CmdID>
  <Item>
    <Target>
      <LocURI>./Device/Vendor/MSFT/Policy/Config/Printers/RestrictDriverInstallationToAdministrators</LocURI>
    </Target>
    <Meta><Format xmlns="syncml:metinf">int</Format></Meta>
    <Data>1</Data>
  </Item>
</Replace>
```

3. N'utiliser que les chemins validés dans votre locataire. Certains nœuds du CSP Printers ne sont pas exposés sur toutes les versions de Windows ; si un nœud manque, utiliser l'option B.
4. Appliquer le profil à tous les appareils. Seul un groupe intelligent couvert par 8.3 peut recevoir une valeur assouplie.

### 10.2 Option B : script PowerShell (solution de repli)

Si une valeur ne peut pas être posée par profil, déployer ce script en tant que **SYSTEM** depuis *Appareils > Scripts > Windows > Ajouter* :

```powershell
# Base de durcissement Point and Print (section 8). Exécuté en SYSTEM.
$base    = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers'
$pap     = "$base\PointAndPrint"
$servers = 'PRTSRV01.exemple.local;PRTSRV02.exemple.local'
# Base = 1. Mettre 0 uniquement pour les appareils du groupe d'exception approuvé sous 8.3.
$restrictAdmins = 1

if (-not (Test-Path $base)) { New-Item -Path $base -Force | Out-Null }
if (-not (Test-Path $pap))  { New-Item -Path $pap  -Force | Out-Null }

Set-ItemProperty -Path $base -Name 'RestrictDriverInstallationToAdministrators' -Value $restrictAdmins -Type DWord
Set-ItemProperty -Path $pap  -Name 'Restricted'                   -Value 1        -Type DWord
Set-ItemProperty -Path $pap  -Name 'TrustedServers'               -Value 1        -Type DWord
Set-ItemProperty -Path $pap  -Name 'ServerList'                   -Value $servers -Type String
Set-ItemProperty -Path $pap  -Name 'NoWarningNoElevationOnInstall' -Value 0       -Type DWord
Set-ItemProperty -Path $pap  -Name 'UpdatePromptSettings'          -Value 0       -Type DWord

Write-Output "Base Point and Print appliquée (RestrictDriverInstallationToAdministrators=$restrictAdmins)"
```

### 10.3 Remarques pour Workspace ONE

- Les scripts s'exécutent en SYSTEM et ne sont pas réappliqués après une mise à jour majeure de Windows, sauf planification. Utiliser une récurrence quotidienne si la console le permet.
- La variable `$servers` doit correspondre aux serveurs approuvés de la section 8.1 et au nom du serveur dans `printers.json`.
- Documenter l'appartenance au groupe intelligent : c'est le seul registre des appareils en exception.

### 10.4 Vérification

Exécuter le contrôle de la section 8.4 sur l'appareil, et vérifier le statut de retour du script dans la console.

---

## 11. Tutoriel : serveur Windows pour clients macOS et Linux

Méthode recommandée : **IPP** via le rôle *Impression Internet*. Les clients macOS et Linux parlent à IIS en HTTP, qui relaie vers la file d'impression Windows. Cette méthode n'est pas pilotée par le script d'export : elle se configure à la main, une fois, par serveur.

### 11.1 Prérequis côté serveur Windows

- Rôle **Services d'impression et de numérisation**, avec le service de rôle **Impression Internet**. Son installation ajoute IIS et ses dépendances.
- La file d'impression est **partagée** et possède un pilote acceptant **PostScript** (pilote constructeur ou pilote universel PostScript). C'est le pilote utilisé par la file d'impression « Générique PostScript » côté macOS et Linux.
- **Pare-feu** : autoriser le port TCP 80 (HTTP) depuis les sous-réseaux clients. En production, préférer HTTPS (port 443) avec un certificat interne, car IPP en clair transmet les identifiants.
- **Droits** : par défaut, l'Impression Internet demande une authentification Windows. Créer un groupe de domaine (par exemple `GRP-Impression-Clients-Mac-Linux`) et lui accorder le droit **Imprimer** sur la file d'impression.

### 11.2 Vérifier côté serveur

```powershell
Get-Printer -Name IMP-1R-01 | Select-Object Name, Shared, ShareName
Get-Service Spooler, W3SVC
```

Depuis un poste du réseau, ouvrir `http://PRTSRV01.exemple.local/printers/IMP-1R-01/.printer`. Une boîte d'authentification doit apparaître : saisir un compte du domaine membre du groupe autorisé. Une réponse de type page IPP ou XML confirme que la file d'impression est accessible.

### 11.3 macOS

1. Ouvrir **Réglages Système > Imprimantes et scanners**, puis cliquer sur **Ajouter une imprimante**.
2. Ouvrir l'onglet **IP**.
3. Renseigner :
   - Protocole : **IPP**
   - Adresse : `PRTSRV01.exemple.local`
   - File d'impression : `printers/IMP-1R-01`
   - Pilote : **Générique PostScript**. Choisir **AirPrint** seulement si macOS le propose réellement pour cette file d'impression.
4. Si macOS demande des identifiants, saisir un compte du domaine au format `DOMAINE\utilisateur`.

> Windows Server n'annonce pas toujours la prise en charge d'IPP Everywhere (impression sans pilote). Si macOS ne propose que des pilotes génériques qui échouent, revenir au pilote PostScript et vérifier que le pilote de la file d'impression accepte PostScript.

### 11.4 Linux (CUPS)

Installer CUPS si besoin (Debian/Ubuntu : `sudo apt install cups cups-filters`), puis :

```bash
# Méthode sans pilote (IPP Everywhere), à tester en premier
sudo lpadmin -p IMP-1R-01 -E -v ipp://PRTSRV01.exemple.local/printers/IMP-1R-01 -m everywhere

# Repli si le serveur ne prend pas en charge IPP Everywhere
sudo lpadmin -p IMP-1R-01 -E -v ipp://PRTSRV01.exemple.local/printers/IMP-1R-01 -m drv:///sample.drv/generic.ppd
```

Si le serveur exige une authentification, CUPS la demande au moment de l'impression. Pour la stocker sur la file d'impression, utiliser l'attribut `auth-info-required` (`-o auth-info-required=username,password`). Valider la syntaxe sur votre version de CUPS avant déploiement.

### 11.5 Option SMB (repli, déconseillée)

Utile seulement si IPP est bloqué et qu'aucun autre choix n'est possible.

- macOS : onglet **Windows** de la fenêtre d'ajout d'imprimante, selon les versions du système. Moins fiable qu'IPP.
- Linux : le backend SMB de CUPS demande les identifiants dans l'URI :

```bash
sudo lpadmin -p IMP-1R-01 -E \
  -v "smb://DOMAINE%5Cutilisateur:MotDePasse@PRTSRV01/IMP-1R-01" \
  -m "drv:///sample.drv/generic.ppd"
```

> Ce mot de passe apparaît dans `lpstat -v` et dans la liste des processus. N'utiliser qu'un compte de service à droits minimaux, uniquement sur des postes de confiance. Le paquet `smbclient` doit être installé.

### 11.6 Vérification côté client

```bash
lpstat -p IMP-1R-01 -l          # État et capacités de la file d'impression
lp -d IMP-1R-01 test.txt        # Impression de test
```

Côté serveur, le travail doit apparaître dans la file d'impression :

```powershell
Get-PrintJob -PrinterName IMP-1R-01
```

---

## 12. Structure du dépôt

```
PrinterTutorialGenerator/
├── README.md                    Documentation en anglais
├── README.fr.md                 Documentation en français
├── LICENSE                      Licence MIT
├── Export-PrinterList.ps1       Export des imprimantes depuis un serveur Windows
├── editeur-imprimantes.html     Éditeur de configuration (technicien)
├── index.html                   Site utilisateur
├── printers.example.json        Exemple de données anonymisé
└── printers.json                Données réelles (ne pas versionner, voir .gitignore)
```

Ajouter `printers.json` et `mapping.csv` au `.gitignore` pour ne pas publier les noms de serveurs et d'équipements de l'entreprise.

## 13. Format de données `printers.json`

```json
{
    "config": {
        "title_fr": "Assistant Installation Imprimantes",
        "subtitle_fr": "Installation guidée des imprimantes réseau",
        "title_en": "Printer Installation Assistant",
        "subtitle_en": "Guided network printer installation",
        "logo_url": "",
        "logo_position": "center",
        "footer": {
            "fr": {
                "title": "Besoin d'aide ?",
                "subtitle": "Support technique :",
                "email": "support@exemple.local",
                "phone": "",
                "hours": "",
                "website": "",
                "portal_text": "",
                "portal_url": ""
            },
            "en": {
                "title": "Need help?",
                "subtitle": "Technical support:",
                "email": "support@exemple.local",
                "phone": "",
                "hours": "",
                "website": "",
                "portal_text": "",
                "portal_url": ""
            }
        }
    },
    "printers": [
        {
            "name": "Imprimante IMP-1R-01",
            "location": "1er étage - Entrée principale",
            "queue": "IMP-1R-01",
            "server": "PRTSRV01.exemple.local",
            "mac-driver": "Generic PostScript Printer"
        }
    ]
}
```

| Champ | Description |
|---|---|
| `name` | Nom affiché à l'utilisateur. |
| `location` | Emplacement lisible, utilisé pour la recherche. |
| `queue` | Nom de partage de la file d'impression sur le serveur. |
| `server` | Nom DNS du serveur d'impression. |
| `mac-driver` | Pilote à utiliser côté macOS/Linux (PostScript générique par défaut). |

## 14. Dépannage

| Symptôme | Cause probable | Action |
|---|---|---|
| `printers.json` renvoie 404 | Site IIS mal lié au dossier | Vérifier la liaison du site et les droits NTFS. |
| Le script renvoie « accès refusé » | Compte sans droit de lecture sur le spouleur | Ajouter le compte de service au groupe *Opérateurs d'impression*. |
| Pilote refusé sur un poste standard | Serveurs approuvés non configurés, ou pilote non signé | Revoir les sections 7.3 et 7.5. |
| Le site affiche « impossible de charger la liste » | `printers.json` absent ou JSON invalide | Vérifier que les deux fichiers sont dans le même dossier, et valider le JSON. |
| macOS n'imprime pas | Pilote incompatible | Passer en IPP Everywhere ou PostScript générique. |
| Liste vide dans l'éditeur | Fichier JSON invalide | Valider le JSON (éditeur, onglet JSON brut). |

## 15. Licence

Distribué sous licence MIT. Voir [LICENSE](LICENSE).
