<div align="center">

# 🎥 Milestone Toolkit

**Outil d'administration et d'export pour Milestone XProtect VMS**

Interface graphique moderne (WPF) construite sur le module PowerShell **MilestonePSTools** —
exporte les caméras, le matériel, la rétention et les enregistrements vers **Excel / CSV**,
capture des snapshots, gère les groupes et crée des alarmes **en masse**.

![Windows](https://img.shields.io/badge/Windows-10%2F11%20%7C%20Server%202016%2B-0078D6?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell)
![Langues](https://img.shields.io/badge/Langues-FR%20%7C%20EN-brightgreen)

<img width="1244" alt="Interface Milestone Toolkit" src="https://github.com/user-attachments/assets/909442eb-a8ec-4d50-b90f-e99df0070a9c" />

</div>

---

## ✨ Pourquoi cet outil

Milestone XProtect ne propose pas nativement d'export simple et exploitable de la configuration.
Milestone Toolkit comble ce manque et fait gagner un temps considérable sur les grosses installations :

- 📊 **Export complet** des caméras et du matériel vers Excel (snapshots inclus)
- 🕵️ **Audit** de la rétention et des enregistrements
- 📸 **Snapshots** en masse (live ou historique)
- 🚨 **Création d'alarmes en masse** en quelques clics
- 🌍 Interface **bilingue** (français / anglais), thème sombre

---

## 🚀 Lancement

1. Télécharger la dernière version depuis la page [**Releases**](../../releases)
2. Décompresser l'archive
3. Double-cliquer sur **`Demarrer Milestone Toolkit.bat`**

> Au premier lancement, l'écran de démarrage vérifie les dépendances et les installe
> automatiquement si Internet est disponible. Aucune installation manuelle requise.

---

## 🧰 Fonctionnalités

### 📸 Snapshots

| Action | Description |
|--------|-------------|
| **Snapshot – Sélection** | Capture la caméra sélectionnée via le dialogue Milestone |
| **Snapshot – Toutes les caméras** | Capture chaque caméra du système, avec progression et annulation |
| **Snapshot – Presets PTZ** | Parcourt les presets PTZ et capture une image à chaque position |

Chaque action supporte deux modes : **Live** (dernière image) ou **Historique** (image la plus proche d'une date/heure).

### 🛠️ Gestion

| Action | Description |
|--------|-------------|
| **Export Hardware (Excel)** | Rapport Excel configurable : sélection des colonnes (matériel, flux vidéo, rétention, snapshots). Les mots de passe sont **exclus par défaut**. Détection fiable du flux **enregistré vs live** par caméra. |
| **Grouper par Modèle** | Crée des groupes de caméras dans Milestone, organisés par modèle |
| **🚨 Créer des alarmes** | **Création d'alarmes en masse** — voir section dédiée ci-dessous |

<img width="513" alt="Sélecteur de colonnes de l'export" src="https://github.com/user-attachments/assets/5bb4cf19-e0f3-4684-9fce-6d1d328feff4" />

### 📡 Monitoring

| Action | Description |
|--------|-------------|
| **État des caméras** | État temps réel (OK / hors ligne / erreur) via l'Event Server. Caméras désactivées ignorées. Export CSV. |
| **Dates d'enregistrement** | Premier et dernier enregistrement disponible par caméra, avec durée totale de rétention. Export CSV. |

### 🔍 Diagnostic

| Action | Description |
|--------|-------------|
| **Stats Enregistrement (7 j)** | Statistiques d'enregistrement et de mouvement par caméra sur 7 jours (FPS, bitrate, résolution). Export CSV. |
| **Informations Licence** | Produits licenciés, dates d'expiration et canaux utilisés |

---

## 🚨 Création d'alarmes en masse

Le bouton **Créer des alarmes** ouvre une fenêtre complète et flexible pour générer plusieurs
définitions d'alarme d'un coup — idéal pour appliquer une même alarme (ex. « caméra hors ligne »)
à tout un parc.

**Deux modes :**
- **Nouvelle alarme** — choix du groupe d'événement, du type, de la priorité et de la catégorie.
  Les listes sont **peuplées dynamiquement depuis votre serveur** (aucune valeur codée en dur).
- **Dupliquer une existante** — reprend les réglages d'une alarme déjà configurée.

**Portée au choix :**
- Toutes les caméras · une sélection · **une seule alarme globale** ou **une alarme par caméra**
  (nom via un modèle `{camera}`).

**Sûr par conception :** un test préalable valide le type d'événement choisi **avant** toute
création en masse, et les alarmes restent supprimables (Management Client ou `Remove-VmsAlarmDefinition`).

---

## 📋 Prérequis

- **Windows** 10 / 11 ou Windows Server 2016+
- **PowerShell 5.1** (inclus dans Windows)
- **Excel facultatif** : s'il est absent, l'export Hardware bascule automatiquement sur le module
  *ImportExcel* (aucune installation d'Office requise)
- Accès réseau au **Management Server** Milestone XProtect

> Les modules **MilestonePSTools** et **ImportExcel** sont installés automatiquement au premier
> lancement si Internet est disponible.

---

## 🌐 Modes d'installation

### En ligne (par défaut)
Les modules sont téléchargés automatiquement depuis PowerShell Gallery. Aucune action requise.

### Hors ligne (machine sans Internet)
1. Sur une machine **avec** Internet, cliquer **Préparer offline** dans l'écran de démarrage
2. Copier le projet entier (avec le dossier `Dependencies/`) sur la machine cible
3. Lancer normalement — le mode Offline est détecté automatiquement

<img width="562" alt="Écran de démarrage / vérification des dépendances" src="https://github.com/user-attachments/assets/da83ab43-56b6-4d38-97b6-607831601588" />

---

## 🔄 Langues & mises à jour

- **Langues** — français et anglais. Le choix est demandé au premier lancement puis mémorisé dans
  `config.json` (clé `language`).
- **Mise à jour automatique** — au démarrage, l'outil vérifie la dernière release GitHub et propose
  la mise à jour en un clic. L'archive est **vérifiée** (dépôt GitHub officiel figé + empreinte
  **SHA256** publiée dans les notes de release), et l'ancienne version est **sauvegardée** avec
  **restauration automatique** en cas d'échec.

---

## ⚙️ Configuration

Fichier `config.json` :

```json
{
    "outputDirectory": "./Output",
    "snapshotQuality": 95,
    "csvDelimiter": ";",
    "csvEncoding": "UTF8",
    "language": "fr",
    "autoLogin": false,
    "autoUpdate": {
        "enabled": true,
        "repo": "Nothinx-44/XProtect-Export-Tool-to-Excel-MilestonePSTools-GUI-"
    }
}
```

| Paramètre | Description | Défaut |
|-----------|-------------|--------|
| `outputDirectory` | Dossier de sortie (snapshots, Excel, CSV) | `./Output` |
| `snapshotQuality` | Qualité JPEG des snapshots (1–100) | `95` |
| `csvDelimiter` | Séparateur des fichiers CSV | `;` |
| `csvEncoding` | Encodage des fichiers CSV | `UTF8` |
| `language` | Langue de l'interface (`fr` / `en`), mémorisée au 1ᵉʳ lancement | — |
| `autoLogin` | Connexion auto du dialogue Milestone au dernier serveur. Désactivée par défaut (un ancien serveur inaccessible ferait planter le démarrage) | `false` |
| `autoUpdate.enabled` | Vérification de mise à jour au démarrage | `true` |
| `autoUpdate.repo` | Informatif : le dépôt de mise à jour est **figé dans le code** par sécurité | — |

Le dossier de sortie peut aussi être changé en cours d'utilisation via le bouton **Changer** dans la barre latérale.

---

## 📁 Structure du projet

```
Milestone Toolkit/
├── Demarrer Milestone Toolkit.bat   # Point d'entrée (double-clic)
├── config.json                      # Configuration
├── Save-Dependencies.ps1            # Préparation du mode offline
├── Dependencies/                    # Modules offline (optionnel)
├── Logs/                            # Logs journaliers (auto, purge > 30 jours)
├── Output/                          # Fichiers générés (auto)
└── src/
    ├── Bootstrap.ps1                # Démarrage : langue, vérification, mise à jour
    ├── App.ps1                      # Chargement UI et événements
    ├── Version.ps1                  # Numéro de version (source unique)
    ├── UI/MainWindow.xaml           # Interface WPF (thème sombre Catppuccin)
    ├── Lang/                        # Traductions fr.ps1 / en.ps1
    ├── Actions/                     # Snapshots, export, alarmes, monitoring…
    └── Core/                        # Modules, updater, logging, console…
```

---

## 💡 Cas d'usage

- Audit de parc caméras · Vérification de la rétention · Export client
- Analyse de fonctionnement · Maintenance système · Déploiement d'alarmes en masse

---

<div align="center">

**Made by Vincent Le Bonhomme**

<sub>Milestone XProtect · export Excel · MilestonePSTools GUI · audit vidéosurveillance · rapport caméras</sub>

</div>
