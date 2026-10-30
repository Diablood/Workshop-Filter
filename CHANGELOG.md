# Journal des changements

## 0.3.2 — 2026-10-30

- Les filtres de produits sont réservés aux bâtiments proposant des tâches de production. Ils n’apparaissent plus dans Santé → Opérations des colons.
- Les opérations conservent leur liste complète et leur disposition d’origine, même si un ancien filtre médical a été sauvegardé. Les ateliers de mods restent pris en charge sans dépendre d’une classe d’établi particulière ; l’intégration Dubs reste facultative.

Validation : compilation sans erreur ni avertissement, 33 contrôles de filtrage/recherche, 9 contrôles Scribe et 8 contrôles de séparation ateliers/opérations réussis. Signatures, métadonnées, traductions et intégration Dubs facultative vérifiées. `LayoutChecks` n’a pas été lancé. Le 2026-10-30, le créateur a confirmé « Tests OK » après préparation de la correction 0.3.2. Les scénarios détaillés exécutés et la configuration Dubs n’ont pas été précisés.

## 0.3.1 — 2026-10-30

- Correction de l’identité à la demande du créateur : auteur **Diablood**, package ID `diablood.workshopfilter` et identifiant Harmony aligné.
- Le déploiement local accepte l’ancienne copie `diabl.workshopfilter` pour sa migration et préserve l’identifiant de l’article Workshop.
- Les types sérialisés et clés des filtres restent identiques à 0.3.0 ; aucun changement de logique de filtrage.

Validation : compilation sans erreur ni avertissement, 33 contrôles fonctionnels et 9 contrôles Scribe réussis, cohérence des métadonnées et signatures vérifiée. `LayoutChecks` n’a pas été lancé. La version 0.3.0 avait reçu une validation en jeu du créateur ; 0.3.1 corrige uniquement l’identité et les outils de déploiement associés.

## 0.3.0 — 2026-10-30

- Les filtres sont désormais sauvegardés dans le `BillStack` de chaque atelier et restaurés au chargement. Les anciennes sauvegardes sans données de filtre démarrent sans restriction. Les critères de mod ou de couche disparus sont effacés au chargement.
- Le survol du bouton affiche les critères actifs. Dubs indique également le nombre d’ateliers sélectionnés et les critères différents d’un atelier à l’autre.
- Les listes de mods et de couches disposent d’une recherche par nom et identifiant, insensible à la casse et aux accents, avec prise en charge de plusieurs mots. Le choix « Tous » reste toujours accessible.

Validation : compilation sans erreur ni avertissement, 33 contrôles de filtrage/recherche et contrôles de signatures/XML/traductions/versions réussis. Neuf contrôles supplémentaires avec le sérialiseur Scribe du jeu ont confirmé le rechargement des critères, l’indépendance de deux ateliers, la compatibilité d’un XML sans données de filtre et le nettoyage des mods/couches disparus, sur des fichiers synthétiques séparés des parties. `LayoutChecks` n’a pas été lancé. Le 2026-10-30, l’utilisateur a confirmé « Tests OK » pour la version 0.3.0 ; les scénarios détaillés exécutés n’ont pas été précisés.

## 0.2.0 — 2026-10-30

- Ajout d’une case unique « Compatible nudiste », affichée pour les ateliers produisant des vêtements, en vanilla et avec Dubs Mint Menus. Cochée : ne garder que les recettes ayant un produit compatible nudiste ; décochée : aucune restriction liée à la nudité.
- La compatibilité reprend la règle de `ThoughtWorker_NudistNude` de RimWorld 1.7 : un vêtement est compatible s’il ne compte pas pour la nudité ou s’il ne couvre ni le groupe Torso ni le groupe Legs. Les couvre-chefs et accessoires peuvent donc être inclus. Les objets qui ne sont pas des vêtements sont exclus lorsque la case est cochée.
- Le mod, la couche et la compatibilité nudiste doivent correspondre au même produit final. Réinitialiser désactive aussi la case.
- Fermeture de la fenêtre des filtres par clic à l’extérieur, avec conservation immédiate des sélections.

Validation : compilation sans erreur ni avertissement, 26 contrôles de logique et contrôles de signatures/XML/traductions/versions réussis. `LayoutChecks` n’a pas été lancé. Le 2026-10-30, l’utilisateur a confirmé « Tests OK » après les ajouts de la version 0.2.0, sans préciser les scénarios exécutés.

## 0.1.1 — 2026-10-30

- Le bouton et le libellé « Couche » sont masqués si aucune recette de l’atelier ne produit de vêtement. La détection repose sur les produits déclarés des recettes, et non sur le type ou le nom de l’atelier ; les vêtements de mods et les recettes non encore recherchées sont pris en compte.
- Le filtre par mod reste disponible. La fenêtre se réduit lorsqu’il est le seul critère applicable.
- Dans la sélection multiple de Dubs Mint Menus, le bouton « Couche » reste visible si au moins un atelier sélectionné produit des vêtements.

Validation : compilation sans erreur ni avertissement, 14 contrôles de logique et contrôles de signatures/XML/traductions/versions réussis. `LayoutChecks` n’a pas été lancé. Comportement visuel à confirmer en jeu.

## Outillage — 2026-10-30

- `LayoutChecks` devient facultatif (`build.ps1 -RunLayoutChecks`) pour éviter les analyses antivirus répétées et leur notification sonore lors du déploiement habituel. Les contrôles de logique, signatures, XML, traductions et versions restent automatiques. La version du mod reste 0.1.0 : ce changement concerne uniquement les outils de développement.

## 0.1.0 — 2026-10-30

Première version explicitement numérotée, après les premiers essais locaux.

- Filtres des produits finaux par mod et par couche vanilla ou custom.
- Compatibilité facultative avec les panneaux de recettes de Dubs Mint Menus.
- Correction de l’affichage : une ligne dédiée sous les commandes vanilla évite de recouvrir les boutons de fermeture, collage ou duplication.
- Quand le panneau Dubs est dessiné, seul son bouton de filtre est affiché. Le bouton vanilla revient lorsque ce panneau est masqué.
- Déploiement local automatisé avec sauvegarde, vérification SHA-256 et lanceur Windows.
- Version indiquée dans les métadonnées du mod, la DLL et le journal de démarrage.

Validation : filtres vanilla et Dubs confirmés en jeu par l’utilisateur. Le 2026-10-30, l’utilisateur a également confirmé « Tests OK » après la correction d’affichage. Aucun détail supplémentaire sur les scénarios exécutés n’a été fourni.
