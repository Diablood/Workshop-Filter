# Publication — Workshop Filter 0.3.0

Publication GitHub et Workshop demandée par le créateur le 2026-10-30. Licence MIT choisie pour le code ; couverture cartoon demandée. La version 0.3.0 a reçu un retour utilisateur « Tests OK ». Les scénarios détaillés ne sont pas connus ; les vérifications automatiques sont décrites dans le README principal.

## Contenu de publication

- Couverture : `About/Preview.png`, export carré du master `workshop/assets/preview-master-cartoon.png`. Illustration promotionnelle, pas une capture du jeu.
- Textes français et anglais : `description.*.bbcode.txt` ; notes : `changenote.*.txt`.
- Métadonnées et suivi : `listing.json`.
- Licence du code : `LICENSE` ; traitement distinct des visuels : `LICENSING.md`.

`prepare-release.ps1` compile et vérifie, puis crée une archive et un dossier de contenu propre dans `artifacts/releases/0.3.0/<horodatage>/`. Il ne publie rien. Les sources, outils, décompilations, bibliothèques du jeu et d'autres mods ne font pas partie de l'envoi. `manifest.json` conserve les SHA-256 et reste en dehors du dossier du mod.

## GitHub

Déposer les sources et fichiers nécessaires du projet dans https://github.com/Diablood/Workshop-Filter, puis créer le tag `v0.3.0` et une release avec l'archive préparée et ses sommes de contrôle. Vérifier le commit distant et le contenu téléchargé.

## Steam Workshop

1. Déployer le contenu propre dans `RimWorld/Mods/WorkshopFilter`, jeu fermé, avec `deploy.cmd`.
2. Depuis la liste des mods de RimWorld, sélectionner Workshop Filter et utiliser l'action d'envoi Steam Workshop. La confirmation d'envoi transfère le contenu du dossier du mod : vérifier qu'il ne contient que le manifeste autorisé.
3. Toute acceptation d'accord Steam demandée reste à effectuer par le titulaire du compte.
4. Récupérer `About/PublishedFileId.txt`, reporter cet identifiant dans les sources et `listing.json`, puis réutiliser cet article pour les mises à jour.
5. Enregistrer les descriptions et notes FR/EN, déclarer Harmony comme seul élément requis et garder Dubs Mint Menus facultatif. Vérifier visibilité, aperçu et tags sur la page créée.
6. Vérifier le contenu distribué et sa version après téléchargement. Éviter l'activation simultanée des copies locale et Workshop.

La procédure de l'installation locale a été inspectée : l'uploader utilise `About/Preview.png` et le dossier racine du mod. Le contenu autorisé est défini dans `tools/package-files.json`, avec `About/PublishedFileId.txt` ajouté lorsqu'il existe. L'aperçu est exporté sous 1 Mo, conformément à la documentation Steamworks. Le suivi doit distinguer publication GitHub, envoi Workshop et vérification du téléchargement.
