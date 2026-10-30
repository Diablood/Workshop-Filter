# Publication — Workshop Filter 0.3.1

Publication GitHub et Workshop demandée par le créateur le 2026-10-30. Licence MIT choisie pour le code ; couverture cartoon demandée. La version 0.3.0 a reçu un retour utilisateur « Tests OK ». Les scénarios détaillés ne sont pas connus ; les vérifications automatiques sont décrites dans le README principal.

## État de publication

Correctif 0.3.1 en préparation à la demande du créateur pour utiliser `diablood.workshopfilter`. Le créateur a fermé le jeu pour permettre le redéploiement. L’article Workshop, s’il a déjà été créé, devra être réutilisé ; aucun deuxième article ne doit être créé.

GitHub : sources et [release v0.3.0](https://github.com/Diablood/Workshop-Filter/releases/tag/v0.3.0) publiées. Le tag pointe vers `d48ba59cc46c00a27fda99d8944b7fa0fd53b1f4`, avec l’auteur **Diablood**. L’archive publique a été retéléchargée et ses 12 fichiers vérifiés contre le manifeste. SHA-256 : `7c2404ba73349d1cd9f534ab4e34076173645f222f82e86bb4c8ba7f007c4988`.

Workshop : le créateur a choisi d’effectuer lui-même le premier envoi et de fournir le lien. Attendre ce lien pour renseigner l’identifiant et vérifier la page ; ne pas déclencher un deuxième envoi depuis l’agent. Les textes FR/EN sont prêts. L’icône personnelle `About/ModIcon.png` est conservée sans modification et incluse dans la distribution.

## Contenu de publication

- Couverture : `About/Preview.png`, export carré du master `workshop/assets/preview-master-cartoon.png`. Illustration promotionnelle, pas une capture du jeu.
- Textes français et anglais : `description.*.bbcode.txt` ; notes : `changenote.*.txt`.
- Métadonnées et suivi : `listing.json`.
- Licence du code : `LICENSE` ; traitement distinct des visuels : `LICENSING.md`.

`prepare-release.ps1` compile et vérifie, puis crée une archive et un dossier de contenu propre dans `artifacts/releases/0.3.1/<horodatage>/`. Il ne publie rien. Les sources, outils, décompilations, bibliothèques du jeu et d'autres mods ne font pas partie de l'envoi. `manifest.json` conserve les SHA-256 et reste en dehors du dossier du mod.

## GitHub

Déposer les sources et fichiers nécessaires du projet dans https://github.com/Diablood/Workshop-Filter, puis créer le tag `v0.3.1` et une release avec l'archive préparée et ses sommes de contrôle. Vérifier le commit distant et le contenu téléchargé. Conserver la release 0.3.0 existante comme historique.

## Steam Workshop

1. Déployer le contenu propre dans `RimWorld/Mods/WorkshopFilter`, jeu fermé, avec `deploy.cmd`.
2. Depuis la liste des mods de RimWorld, sélectionner Workshop Filter et utiliser l'action d'envoi Steam Workshop. La confirmation d'envoi transfère le contenu du dossier du mod : vérifier qu'il ne contient que le manifeste autorisé.
3. Toute acceptation d'accord Steam demandée reste à effectuer par le titulaire du compte.
4. Récupérer `About/PublishedFileId.txt`, reporter cet identifiant dans les sources et `listing.json`, puis réutiliser cet article pour les mises à jour.
5. Enregistrer les descriptions et notes FR/EN, déclarer Harmony comme seul élément requis et garder Dubs Mint Menus facultatif. Vérifier visibilité, aperçu et tags sur la page créée.
6. Vérifier le contenu distribué et sa version après téléchargement. Éviter l'activation simultanée des copies locale et Workshop.

La procédure de l'installation locale a été inspectée : l'uploader utilise `About/Preview.png` et le dossier racine du mod. Le contenu autorisé est défini dans `tools/package-files.json`, avec `About/PublishedFileId.txt` ajouté lorsqu'il existe. L'aperçu est exporté sous 1 Mo, conformément à la documentation Steamworks. Le suivi doit distinguer publication GitHub, envoi Workshop et vérification du téléchargement.
