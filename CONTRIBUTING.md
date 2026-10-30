# Développer Workshop Filter

## Organisation du dépôt

- `About/`, `Languages/`, `LoadFolders.xml` et `1.7/` constituent le mod chargé par RimWorld. Ils restent à la racine pour respecter sa structure de chargement.
- `Source/` contient le code C# et le projet du mod.
- `Tests/` contient les contrôles automatisés. Les contrôles de mise en page restent facultatifs.
- `tools/` regroupe les scripts de compilation, de vérification, de déploiement et de préparation des archives, ainsi que le manifeste des fichiers distribués.
- `workshop/` contient les présentations FR/EN, les visuels et le suivi de publication.
- `artifacts/` reçoit les fichiers générés, archives et sauvegardes locales. Git ignore ce dossier.

## Rôle de Directory.Build.props

`Directory.Build.props` est un fichier de configuration de **MSBuild**, le moteur de compilation utilisé par .NET. Ce n’est pas un script à lancer.

Lors de la compilation d’un fichier `.csproj`, .NET cherche ce nom de fichier dans ses dossiers parents et l’importe automatiquement. Sa présence à la racine permet donc de partager les paramètres entre le mod et ses projets de tests.

Dans ce dépôt, il définit uniquement la version : `Version` est le numéro du mod ; `AssemblyVersion` et `FileVersion` en dérivent pour identifier la DLL. Le déplacer dans `tools/` sans ajouter des imports explicites empêcherait sa découverte automatique.

Lors d’un changement de version, aligner `Directory.Build.props`, `About/About.xml` et `CHANGELOG.md`. `tools/check-project.ps1` vérifie cette cohérence avec la DLL compilée.

## Commandes

Depuis la racine du dépôt :

```powershell
# Compiler et exécuter les contrôles habituels, sans installer le mod.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\build.ps1

# Compiler, vérifier et installer dans Mods. Fermer RimWorld auparavant.
.\tools\deploy.cmd

# Afficher la destination sans compiler ni copier.
.\tools\deploy.cmd -WhatIf

# Préparer l’archive et le contenu Workshop, sans les envoyer.
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tools\prepare-release.ps1
```

Le lanceur `tools/deploy.cmd` trouve PowerShell 7 et autorise les scripts pour son processus seulement. Il ne change pas la stratégie d’exécution permanente de Windows.

Les scripts déduisent la racine du dépôt depuis leur propre emplacement : un appel par chemin absolu fonctionne aussi depuis un autre répertoire de travail. Les chemins du jeu et d’Harmony restent configurables avec `-RimWorldDir` et `-HarmonyAssemblyPath`.

Le build habituel ne lance pas `LayoutChecks`. Le contrôle de sauvegarde `tools/check-save-roundtrip.ps1` s’exécute séparément sur des fichiers synthétiques, sans toucher aux parties du joueur.

## Commits lisibles

Chaque commit doit correspondre à un changement cohérent et décrire son résultat en français, avec un verbe concret. Exemples :

- `Mémoriser les filtres de chaque atelier dans la sauvegarde`
- `Masquer le filtre de couche pour les ateliers sans vêtements`
- `Regrouper les scripts de développement dans tools`

Si le titre ne suffit pas, expliquer dans le corps le problème résolu, le comportement obtenu et la validation utile au lecteur. Les titres vagues comme `MAJ`, `Divers` ou `Tests OK` n’expliquent pas une modification.

Regrouper les corrections et leur documentation ; séparer les changements indépendants. Le suivi détaillé des envois appartient à `workshop/README.md`, tandis que `CHANGELOG.md` décrit les évolutions du mod. L’historique et les tags déjà publiés restent stables.
