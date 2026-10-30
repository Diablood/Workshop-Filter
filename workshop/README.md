# Publication — Workshop Filter 0.3.1

Publication GitHub et Workshop demandée par le créateur le 2026-10-30. Licence MIT choisie pour le code ; couverture cartoon demandée. La version 0.3.0 a reçu un retour utilisateur « Tests OK ». Les scénarios détaillés ne sont pas connus ; les vérifications automatiques sont décrites dans le README principal.

## État de publication

Correctif [0.3.1 publié sur GitHub](https://github.com/Diablood/Workshop-Filter/releases/tag/v0.3.1), commit du tag `8f3857d5dfc66f3fd3fe0039388813a2ef658b9f`, à la demande du créateur pour utiliser `diablood.workshopfilter`. L’archive publique a été retéléchargée : ses 12 fichiers et l’installation locale sont identiques au manifeste. SHA-256 : `0eb6705e705b781db68bfa092a44d7065ff0ab9c5a37a130a6db1d6ab614b06b`.

Le créateur a fermé le jeu pour permettre le redéploiement de 0.3.1. L’entrée de ce mod dans le fichier ModsConfig.xml actif a été migrée vers le nouvel identifiant après sauvegarde de l’original dans artifacts/backups. Aucun identifiant Workshop n’existait encore lors de ce redéploiement. L’article Workshop, s’il est créé ensuite, devra être réutilisé ; aucun deuxième article ne doit être créé.

Historique GitHub : la [release v0.3.0](https://github.com/Diablood/Workshop-Filter/releases/tag/v0.3.0) reste conservée avec son ancien package ID. Son tag pointe vers `d48ba59cc46c00a27fda99d8944b7fa0fd53b1f4`. Sa vérification initiale portait sur 12 fichiers, SHA-256 `7c2404ba73349d1cd9f534ab4e34076173645f222f82e86bb4c8ba7f007c4988`. Utiliser désormais 0.3.1.

Workshop : premier envoi effectué par le créateur, article [Workshop Filter](https://steamcommunity.com/sharedfiles/filedetails/?id=3830142536), identifiant **3830142536**. Visibilité **Masquée (privée)** vérifiée dans la session du propriétaire et explicitement maintenue à sa demande le 2026-10-30. Ne pas passer en public sans nouvelle instruction. Descriptions et notes FR/EN enregistrées ; Harmony déclaré comme seul élément requis, Dubs Mint Menus reste facultatif. L’icône personnelle `About/ModIcon.png` est conservée sans modification.

Le téléchargement Workshop affiche la version 0.3.1, l’auteur Diablood et le package ID `diablood.workshopfilter`. Ses 12 fichiers de contenu correspondent à la copie locale utilisée pour l’envoi ; `About/PublishedFileId.txt` identifie le même article et est maintenant conservé dans les sources pour les prochaines mises à jour. Voir `verified-files-0.3.1.json`.

La DLL envoyée a été recompilée par le créateur après le tag GitHub : sa version informative porte le suffixe Git `a66449bdd023fda072425309b1e569f8f46eefec`, tandis que l’archive GitHub initiale porte `e2dc37e5b42ad74e7f6ff3778b8c4817dc6a1b72`. La comparaison des 175 signatures et corps de méthodes IL confirme leur identité. Les SHA-256 binaires diffèrent ; la release GitHub et son tag existants ne sont pas réécrits. Le dépôt conserve la DLL effectivement téléchargée du Workshop.

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
