# Workshop Filter — RimWorld 1.7

Version **0.3.2**. Ajoute **Filtrer les produits** sur une ligne dédiée sous les commandes d’ajout de tâche dans les ateliers. Les opérations médicales des colons ne sont pas filtrées et conservent leur disposition habituelle. Historique : [CHANGELOG.md](CHANGELOG.md).

Dépôt GitHub du projet : [Diablood/Workshop-Filter](https://github.com/Diablood/Workshop-Filter).

[English](README.en.md) · Code sous [licence MIT](LICENSE) ; visuels traités séparément dans [LICENSING.md](LICENSING.md).

Auteur : **Diablood**. Identifiant du mod : `diablood.workshopfilter` depuis 0.3.1 (anciennement `diabl.workshopfilter`). Le déploiement local reconnaît l’ancienne copie et conserve l’identifiant de l’article Workshop lorsqu’il existe. Après mise à jour, vérifier que le nouvel identifiant est actif dans la liste de mods/RimSort. Les types C# et clés de sauvegarde des filtres n’ont pas changé.

- **Par mod** : utilise le mod qui définit le produit final, y compris Core et les DLC comme entrées distinctes. Le mod de la recette n’est pas utilisé.
- **Par couche de vêtement** : récupère les `ApparelLayerDef` des vêtements fabriqués dans cet atelier. Les couches vanilla et custom sont proposées automatiquement, avec leur mod d’origine.
- Le bouton **Couche** n’apparaît que si au moins une recette de l’atelier produit un vêtement, y compris les recettes de mods et celles non encore recherchées. Aucun atelier n’est présumé dédié à la couture : seules ses recettes comptent. Avec plusieurs ateliers sélectionnés dans Dubs, un seul atelier produisant des vêtements suffit à proposer ce critère. Le filtre par mod reste toujours accessible.
- **Compatible nudiste** : une case unique, proposée avec les filtres de vêtements. Cochée, elle affiche uniquement les recettes ayant un vêtement compatible avec la nudité ; décochée, elle n’applique aucune restriction de ce type. La règle vanilla est utilisée : le vêtement ne compte pas pour la nudité, ou ne couvre ni le torse ni les jambes. Les couvre-chefs et accessoires compatibles sont donc inclus ; les objets non vestimentaires sont exclus lorsque la case est cochée.
- Les sélections se combinent : un même produit doit satisfaire tous les critères actifs. Un vêtement multicouche apparaît pour chacune de ses couches.
- **Réinitialiser** retrouve la liste normale. Les recettes sans produit déclaré restent visibles sans filtre et sont exclues lorsqu’un filtre est actif.

Les filtres concernent uniquement le menu d’ajout. Ils ne changent ni les ingrédients, ni les tâches existantes, ni la production. Chaque atelier conserve sa propre sélection dans la sauvegarde. Les anciennes sauvegardes commencent sans filtre ; si un mod ou une couche disparaît, le critère correspondant est effacé au chargement.

Le survol du bouton résume les filtres actifs. Dans Dubs, une sélection multiple indique aussi les critères différents selon les ateliers. Les listes de mods et de couches proposent une recherche par nom ou identifiant, sans distinction de casse ou d’accent ; plusieurs mots peuvent être saisis dans n’importe quel ordre.

Un clic à l’extérieur ferme la fenêtre des filtres. Les sélections s’appliquent immédiatement et sont conservées après fermeture.

## Utilisation et installation

Fermer RimWorld, puis exécuter :

```powershell
.\tools\deploy.cmd
```

Le lanceur utilise PowerShell 7 (installé ou fourni avec Codex) et autorise les scripts uniquement pour ce processus, sans modifier la stratégie d’exécution permanente de Windows. Il fonctionne depuis Windows PowerShell ou une invite de commandes.

Cette commande compile, exécute les contrôles puis installe le mod dans `D:\SteamLibrary\steamapps\common\RimWorld\Mods\WorkshopFilter`. Les chemins sont configurables avec `-RimWorldDir` et `-HarmonyAssemblyPath`, comme pour `tools/build.ps1`. `.\tools\deploy.cmd -WhatIf` affiche la destination sans compiler ni copier. `tools/deploy.ps1` reste utilisable directement dans un PowerShell autorisant les scripts. Les scripts calculent les chemins depuis leur emplacement ; ils fonctionnent aussi depuis un autre répertoire de travail.

Seuls les fichiers nécessaires au mod et le README sont copiés. Une installation précédente portant le même packageId est sauvegardée dans `artifacts/backups` avant remplacement ; elle est restaurée si la copie ou sa vérification échoue. Le script vérifie le contenu par SHA-256 et s’arrête si le jeu tourne ou si la destination appartient à un autre mod. Les fichiers obsolètes de l’ancienne installation sont éliminés lors du remplacement.

Activer Harmony, puis Workshop Filter. Dans l’onglet des tâches d’un atelier, ouvrir **Filtrer les produits**, choisir les critères, fermer, puis cliquer **Ajouter une tâche**. Pour compiler sans installer, utiliser `./tools/build.ps1`.

## Développement

L’organisation des fichiers, le rôle de `Directory.Build.props` et les conventions de commit sont décrits dans [CONTRIBUTING.md](CONTRIBUTING.md). Tous les scripts sont regroupés dans `tools/`.

La compilation cible .NET 10 et les assemblies de l’installation locale **1.7.4990 rev1069**. Les chemins du jeu et d’Harmony sont configurables :

La version du mod suit `MAJEURE.MINEURE.CORRECTIF`, distinctement de la version du jeu. `Directory.Build.props` est une configuration .NET automatiquement chargée depuis la racine par les projets du mod et des tests ; il centralise la version et les numéros de la DLL. Ce fichier ne s’exécute pas. `About/About.xml` et `CHANGELOG.md` doivent être mis à jour avec lui lors d’un changement de version. La compilation vérifie leur cohérence. Les premiers essais locaux n’avaient pas de version explicite ; la numérotation débute à 0.1.0.

```powershell
./tools/build.ps1 -RimWorldDir 'D:\SteamLibrary\steamapps\common\RimWorld' -HarmonyAssemblyPath 'chemin\1.7\Assemblies\0Harmony.dll'
```

Trois patches Harmony : `BillStack.DoListing` ajoute le bouton et enveloppe le générateur natif des options ; `ThingDef.AllRecipes` retourne une copie filtrée uniquement pendant cette génération et pour cet atelier ; `BillStack.ExposeData` sauvegarde les critères sous la clé `workshopFilter` (`modId`, `layer`, `nudistOnly`). La liste globale en cache reste intacte. Le contexte est restauré même en cas d’exception. Les actions natives, styles idéologiques, contrôles de recherche et exigences de fabrication restent pris en charge par le générateur d’origine.

**Dubs Mint Menus est facultatif et pris en charge** : un bouton de filtrage est ajouté au-dessus de la recherche de son panneau de recettes, dans l’onglet d’un atelier et dans sa fenêtre globale des ateliers. La sélection d’un atelier est partagée entre l’interface vanilla et Dubs. Pour plusieurs ateliers sélectionnés, changer un filtre dans le panneau Dubs l’applique à tous les ateliers sélectionnés ; la liste réunit les recettes correspondant aux filtres de chacun. Les recherches et tris de Dubs se combinent avec ces filtres. Les modèles de tâches et les contrôles de fabrication de Dubs restent indépendants des filtres d’affichage.

L’intégration est détectée au chargement et ne crée aucune dépendance à la DLL de Dubs. Sans ce mod, le fonctionnement vanilla reste disponible. Si sa méthode d’affichage change, l’intégration est désactivée avec un avertissement dans le journal.

Lorsque le panneau de recettes Dubs est effectivement dessiné, son bouton remplace celui du panneau vanilla. Si le panneau Dubs est masqué, le bouton vanilla revient sur sa ligne dédiée ; les commandes de la barre supérieure gardent leur place.

Compatibilité prévue avec les autres ateliers moddés utilisant `BillStack.DoListing` et `ThingDef.AllRecipes`. Les autres menus entièrement remplacés peuvent nécessiter une adaptation. Les recettes dont les produits sont générés uniquement par un worker, sans `RecipeDef.products`, n’exposent pas de produit utilisable pour ces filtres.

## Vérification

`tools/build.ps1` compile le mod et exécute 33 contrôles de logique (filtres des produits et recherche textuelle), ainsi que les contrôles de signatures, XML, traductions et versions. Le déploiement habituel ne compile ni ne lance `LayoutChecks` : son lancement déclenche une analyse antivirus audible sur cette machine.

`./tools/check-save-roundtrip.ps1` effectue séparément 9 contrôles de sauvegarde/rechargement avec le sérialiseur Scribe du jeu installé et 8 contrôles de séparation entre ateliers et opérations médicales, y compris un ancien filtre médical sauvegardé. Il s’exécute depuis PowerShell sans créer ni lancer d’exécutable de test. Les fichiers XML synthétiques sont écrits dans `artifacts/save-check`, sans toucher aux parties ni à la configuration du joueur. Ces contrôles ne remplacent pas un test de partie complète en jeu.

Les 9 contrôles supplémentaires de mise en page et de chargement sans Dubs restent disponibles uniquement sur demande explicite avec `./tools/build.ps1 -RunLayoutChecks`. Ils vérifient la transformation des deux décalages du panneau natif sur l’assembly du jeu installé, l’espace réservé au filtre et son retrait lorsque Dubs dessine son panneau. Aucun rendu du jeu n’est exécuté : cela ne remplace pas une vérification visuelle en jeu.

Parcours manuel :

1. Charger une partie existante avec Harmony et ce mod ; vérifier l’absence d’erreur au chargement.
2. Sur un établi de couture, sélectionner Core puis une couche vanilla ; ajouter une tâche et vérifier son produit.
3. Avec un mod de vêtements ajoutant une couche, vérifier que cette couche apparaît et sélectionne les bonnes recettes.
4. Vérifier qu’un vêtement multicouche apparaît pour toutes ses couches et que les deux filtres portent sur le même produit.
5. Sur un autre atelier, vérifier le filtrage par mod et l’indépendance des sélections ; réinitialiser une liste vide.
6. Vérifier les recettes non recherchées et les styles idéologiques ; ajouter une tâche, fermer et rouvrir son onglet.
7. Choisir des filtres différents sur deux ateliers, sauvegarder et recharger : les tâches et les sélections de filtres doivent rester identiques. Charger aussi une sauvegarde faite avant 0.3.0 : aucun filtre ne doit être actif par défaut.
8. Ouvrir Santé → Opérations sur un colon : aucun bouton de filtre ni espace supplémentaire ; la liste des opérations reste complète, même après avoir filtré un atelier. Vérifier avec et sans Dubs Mint Menus.

Vérification Dubs : sélectionner un filtre dans l’onglet d’un atelier et confirmer que le panneau Dubs se réduit ; tester sa recherche, une sélection sans résultat et la réinitialisation. Dans la fenêtre globale Dubs, sélectionner plusieurs ateliers et changer un filtre. Tester également avec Dubs désactivé. Vérifier que les modèles de tâches restent disponibles et applicables indépendamment du filtre.

État : retours « Tests OK » de l’utilisateur pour 0.1.0, 0.2.0 et 0.3.0 le 2026-10-30. Les scénarios détaillés exécutés n’ont pas été précisés. Le parcours de régression couvre la persistance par atelier (vanilla et Dubs), les sauvegardes anciennes, le résumé au survol et la recherche (nom, identifiant, accents, aucun résultat et choix « Tous »). Après retrait d’un mod ou d’une couche sur une copie de sauvegarde, vérifier l’effacement du seul critère disparu. Les signatures des patches, les XML, les traductions, la cohérence des versions et l’absence de dépendance obligatoire à Dubs sont contrôlés par `tools/check-project.ps1`.
