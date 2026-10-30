// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'OBIC';

  @override
  String get tagline => 'Vie sociale et services du quotidien en Chine';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabServices => 'Services';

  @override
  String get tabMoments => 'Moments';

  @override
  String get tabDiscover => 'Découvrir';

  @override
  String get tabMessages => 'Messages';

  @override
  String get tabOrders => 'Demandes';

  @override
  String get tabMe => 'Moi';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get homeGreeting => 'Vie sociale et Chine au quotidien';

  @override
  String get homeHint =>
      'Discussions, Moments, amis et appels — plus repas, hôtels, santé, voyages et plus.';

  @override
  String get servicesTitle => 'Tous les services';

  @override
  String get servicesHint =>
      'Parcourez le catalogue librement. Une demande exige une connexion.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesHint => 'Assistance, amis et alertes.';

  @override
  String get messagesEmpty => 'Aucune conversation. Écrivez à l’équipe.';

  @override
  String get messagesEmptyGuest =>
      'Connectez-vous pour voir vos discussions et écrire à l’équipe.';

  @override
  String get messagesNoPreview => 'Pas encore de messages';

  @override
  String get chatSupportTitle => 'Assistance OBIC';

  @override
  String get chatTalkToStaff => 'Parler à l’équipe';

  @override
  String get chatTalkToStaffDone => 'L’équipe répondra ici bientôt';

  @override
  String get chatTalkToStaffBusy => 'Connexion…';

  @override
  String get chatHandoffTitle => 'Contacter l’équipe';

  @override
  String get chatHandoffHint =>
      'Choisissez la succursale et le service pour joindre le bon bureau.';

  @override
  String get chatHandoffBranch => 'Succursale';

  @override
  String get chatHandoffService => 'Service / bureau';

  @override
  String get chatHandoffOrderRef => 'Référence de demande (facultatif)';

  @override
  String get chatHandoffOrderRefHint => 'ex. visa ou numéro de commande';

  @override
  String get chatHandoffNote => 'Note (facultatif)';

  @override
  String get chatHandoffNoteHint => 'Courte note pour l’équipe';

  @override
  String get chatHandoffSubmit => 'Me mettre en relation';

  @override
  String get chatHandoffCancel => 'Annuler';

  @override
  String get chatHandoffUseNearest => 'Succursale la plus proche';

  @override
  String get chatAddPeopleTitle => 'Ajouter des personnes';

  @override
  String get chatAddPeopleHint =>
      'Inviter d’autres agents de la succursale dans cette discussion';

  @override
  String get chatAddPeopleEmpty => 'Aucun autre agent à ajouter';

  @override
  String get chatAddPeopleSubmit => 'Ajouter la sélection';

  @override
  String get chatHandoffSummaryTitle => 'Résumé pour le secrétariat';

  @override
  String get chatInputHint => 'Écrire un message…';

  @override
  String get attachImage => 'Joindre une image';

  @override
  String get attachFile => 'Joindre un fichier';

  @override
  String get attachClear => 'Retirer la pièce jointe';

  @override
  String get chatHoldToTalk => 'Maintenir pour parler';

  @override
  String get chatReleaseToSend => 'Relâcher pour envoyer';

  @override
  String get chatSlideToCancel => 'Relâcher pour annuler';

  @override
  String get chatVoiceTooShort => 'Message vocal trop court';

  @override
  String get chatMicPermissionDenied =>
      'L’autorisation du micro est requise pour les messages vocaux';

  @override
  String get chatVoiceMode => 'Message vocal';

  @override
  String get chatVideoTooLarge =>
      'Vidéo trop lourde (max 80 Mo). Essayez un extrait plus court.';

  @override
  String get chatVideoLargeWarning =>
      'Vidéo de plus de 12 Mo — elle peut disparaître au redéploiement d’essai avant S3. Envoi quand même.';

  @override
  String get chatVideoPickFailed =>
      'Impossible de lire cette vidéo. Essayez un autre extrait.';

  @override
  String get mediaAlbum => 'Album';

  @override
  String get mediaCamera => 'Appareil photo';

  @override
  String get mediaVideo => 'Vidéo';

  @override
  String get mediaVideoTitle => 'Vidéo';

  @override
  String get mediaFromAlbum => 'Depuis l’album';

  @override
  String get mediaRecordVideo => 'Enregistrer une vidéo';

  @override
  String get mediaCameraPermissionDenied =>
      'L’autorisation de l’appareil photo est requise. Activez-la dans Réglages.';

  @override
  String get mediaPhotosPermissionDenied =>
      'L’autorisation de la photothèque est requise. Activez-la dans Réglages.';

  @override
  String get mediaPickFailed =>
      'Impossible d’ouvrir l’appareil photo ou l’album. Réessayez.';

  @override
  String get momentsAddMedia => 'Ajouter';

  @override
  String get momentsTextOnly => 'Texte';

  @override
  String get momentsTakePhoto => 'Prendre une photo';

  @override
  String get chatImageLoadFailed =>
      'Impossible de charger cette image. Vérifiez la connexion et réessayez.';

  @override
  String get chatPreviewVoice => '[Vocal]';

  @override
  String get chatPreviewVideo => '[Vidéo]';

  @override
  String get chatPreviewImage => '[Image]';

  @override
  String get chatPreviewFile => '[Fichier]';

  @override
  String get momentsTitle => 'Moments';

  @override
  String get momentsEmpty =>
      'Pas encore de Moments — soyez le premier à publier.';

  @override
  String get momentsCreate => 'Nouveau Moment';

  @override
  String get momentsHint => 'Quoi de neuf ?';

  @override
  String get momentsPost => 'Publier';

  @override
  String get momentsAnon => 'Utilisateur';

  @override
  String get momentsDelete => 'Supprimer';

  @override
  String get momentsDeleteConfirm =>
      'Supprimer ce Moment ? Vos amis ne le verront plus.';

  @override
  String get momentsDeleted => 'Moment supprimé';

  @override
  String get momentsPrivacyWhoCanSee => 'Qui peut voir';

  @override
  String get momentsPrivacyFriends => 'Tous les amis';

  @override
  String get momentsPrivacyFriendsHint => 'Visible par vos amis mutuels';

  @override
  String get momentsPrivacyPrivate => 'Privé';

  @override
  String get momentsPrivacyPrivateHint => 'Vous seul pouvez voir ceci';

  @override
  String get momentsPrivacyPartial => 'Partager avec…';

  @override
  String get momentsPrivacyPartialHint => 'Seuls les amis choisis peuvent voir';

  @override
  String momentsPrivacyPartialSelected(int n) {
    return '$n amis';
  }

  @override
  String get momentsPrivacyExclude => 'Ne pas partager avec…';

  @override
  String get momentsPrivacyExcludeHint => 'Masquer pour les amis choisis';

  @override
  String momentsPrivacyExcludeSelected(int n) {
    return 'Masqué pour $n';
  }

  @override
  String get momentsPrivacyNeedFriends => 'Choisissez au moins un ami';

  @override
  String get momentsPrivacyDone => 'Terminé';

  @override
  String get momentsOfficial => 'Officiel';

  @override
  String get momentsAddPhotos => 'Photos';

  @override
  String get momentsAddVideos => 'Vidéos';

  @override
  String get momentsAddFiles => 'Fichiers';

  @override
  String get momentsChangeAvatar => 'Changer la photo';

  @override
  String get momentsStaff => 'Équipe';

  @override
  String get momentsJustNow => 'À l’instant';

  @override
  String momentsMinutesAgo(Object n) {
    return 'il y a $n min';
  }

  @override
  String momentsHoursAgo(Object n) {
    return 'il y a $n h';
  }

  @override
  String momentsDaysAgo(Object n) {
    return 'il y a $n j';
  }

  @override
  String get momentsLike => 'J’aime';

  @override
  String get momentsUnlike => 'Je n’aime plus';

  @override
  String get momentsComment => 'Commenter';

  @override
  String get momentsCommentHint => 'Écrire un commentaire…';

  @override
  String get momentsReplyHint => 'Écrire une réponse…';

  @override
  String get momentsCommentAddPhoto => 'Ajouter une photo';

  @override
  String get momentsCommentTakePhoto => 'Prendre une photo';

  @override
  String get momentsCommentSendFailed => 'Impossible d’envoyer le commentaire';

  @override
  String get momentsCommentDelete => 'Supprimer';

  @override
  String get momentsCommentDeleteConfirm => 'Supprimer ce commentaire ?';

  @override
  String get momentsCommentDeleted => 'Commentaire supprimé';

  @override
  String get momentsReply => 'Répondre';

  @override
  String momentsReplyTo(Object name) {
    return 'Répondre à $name';
  }

  @override
  String get momentsRepliedTo => 'a répondu à';

  @override
  String get momentsFavorite => 'Favori';

  @override
  String get momentsFavorited => 'Enregistré dans les favoris';

  @override
  String get momentsReport => 'Signaler';

  @override
  String get momentsReported => 'Signalé — le SuperAdmin va examiner';

  @override
  String get momentsDownload => 'Enregistrer dans Photos';

  @override
  String get momentsSaved => 'Enregistré dans Photos';

  @override
  String get momentsSaveFailed => 'Enregistrement impossible';

  @override
  String get momentsFileSaved => 'Fichier enregistré';

  @override
  String get momentsNoLikes => 'Soyez le premier à aimer';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Vous êtes à jour.';

  @override
  String get notificationsMarkAll => 'Tout marquer comme lu';

  @override
  String get friendsTitle => 'Amis';

  @override
  String get friendsList => 'Vos amis';

  @override
  String get friendsEmpty =>
      'Pas encore d’amis — cherchez par téléphone ou identifiant.';

  @override
  String get friendsAdd => 'Ajouter un ami';

  @override
  String get friendsSearchHint => 'Numéro de téléphone ou ID OBIC';

  @override
  String get friendsIncoming => 'Demandes d’amis';

  @override
  String get friendsAccept => 'Accepter';

  @override
  String get friendsReject => 'Refuser';

  @override
  String get friendsRequestSent => 'Demande d’ami envoyée';

  @override
  String get friendsNewFriends => 'Nouveaux amis';

  @override
  String get friendsNewFriendsEmpty => 'Aucune demande d’ami en attente.';

  @override
  String get friendsOutgoing => 'Envoyées';

  @override
  String get friendsWaiting => 'En attente';

  @override
  String get friendsAcceptedToast => 'Vous êtes maintenant amis';

  @override
  String get friendsSendRequestTitle => 'Demande d’ami';

  @override
  String get friendsVerificationHint => 'Dites bonjour — note facultative';

  @override
  String get friendsSend => 'Envoyer';

  @override
  String get friendsCancel => 'Annuler';

  @override
  String get friendsAlreadyFriends => 'Amis';

  @override
  String friendsRequestAlert(String name) {
    return '$name vous a envoyé une demande d’ami';
  }

  @override
  String get friendsViewRequests => 'Voir';

  @override
  String get friendsEmployeeNote =>
      'Les employés ne peuvent pas ajouter de clients comme amis.';

  @override
  String get friendsByPhone => 'Rechercher';

  @override
  String get friendsByQr => 'Par QR';

  @override
  String get friendsMyQr => 'Mon QR';

  @override
  String get friendsScanQr => 'Scanner le QR';

  @override
  String get friendsQrHint =>
      'Demandez à un ami de scanner votre code, ou scannez le sien.';

  @override
  String get friendsQrPayloadHint => 'Ou collez un code QR OBIC ici';

  @override
  String get friendsQrInvalid => 'Code QR invalide';

  @override
  String get profileObicId => 'ID OBIC';

  @override
  String get profileObicIdHint => '6–20 caractères, commence par une lettre';

  @override
  String get profileObicIdFirstHint =>
      'Définissez votre ID OBIC pour que vos amis vous trouvent. Vous pouvez le changer une fois par an.';

  @override
  String get profileObicIdYearHint =>
      'Vous pouvez changer votre ID OBIC une fois tous les 365 jours.';

  @override
  String profileObicIdCooldownAt(Object date) {
    return 'Prochain changement possible le $date';
  }

  @override
  String profileObicIdCooldownData(Object date) {
    return 'L’ID OBIC ne peut être changé qu’une fois tous les 365 jours. Prochain changement le $date.';
  }

  @override
  String get profileObicIdCooldownHint =>
      'L’ID OBIC ne peut être changé qu’une fois tous les 365 jours.';

  @override
  String get meObicId => 'ID OBIC';

  @override
  String get meObicIdUnset => 'Non défini';

  @override
  String get meMyQr => 'Mon code QR';

  @override
  String get chatComposeHint => 'Message…';

  @override
  String get chatGroup => 'Groupe';

  @override
  String get ordersTitle => 'Mes demandes';

  @override
  String get ordersHint =>
      'Les demandes vous appartiennent ; l’API vérifie que vous en êtes le propriétaire.';

  @override
  String get meTitle => 'Moi';

  @override
  String get meFavorites => 'Favoris';

  @override
  String get mePayServices => 'Paiement et services';

  @override
  String get payDemoBannerTitle => 'Exemple pour l’essai';

  @override
  String get payDemoBannerBody =>
      'Ceci est une démo Paiement et services — mise en page seulement, pas de vrai paiement.';

  @override
  String get payDemoSectionMoney => 'Argent';

  @override
  String get payDemoSectionShortcuts => 'Raccourcis services';

  @override
  String get payDemoSectionOffers => 'Offres OBIC';

  @override
  String get payDemoWallet => 'Portefeuille';

  @override
  String get payDemoTransfer => 'Transférer';

  @override
  String get payDemoReceive => 'Recevoir';

  @override
  String get payDemoCards => 'Cartes';

  @override
  String get payDemoDailyServices => 'Services du quotidien';

  @override
  String get payDemoVisa => 'Visa';

  @override
  String get payDemoBanking => 'Banque';

  @override
  String get payDemoTravel => 'Voyage';

  @override
  String get payDemoOfferVip => 'Chine VIP';

  @override
  String get payDemoOfferPartner => 'Offre partenaire';

  @override
  String get payDemoOfferSeasonal => 'Saisonnier';

  @override
  String get payDemoOfferComing => 'Bientôt';

  @override
  String get payDemoOpenRealServices => 'Ouvrir l’onglet Services';

  @override
  String get payDemoFooter =>
      'Interface d’essai. Le vrai portefeuille et les paiements viendront plus tard.';

  @override
  String payDemoTileSnack(String label) {
    return '$label — exemple seulement';
  }

  @override
  String get meMyPosts => 'Mes publications';

  @override
  String get meWorks => 'Œuvres';

  @override
  String get meChannelHint => 'Voir ma chaîne ici';

  @override
  String get meStatus => 'Statut';

  @override
  String meFriendsCount(int count) {
    return '$count amis';
  }

  @override
  String get meHint =>
      'Profil, langue et connexion — aucun privilège n’est stocké sur l’appareil.';

  @override
  String get meGuestHint =>
      'Connectez-vous pour discuter, Moments, demandes et services du quotidien en Chine.';

  @override
  String get meRole => 'Rôle';

  @override
  String get addressesTitle => 'Mes adresses';

  @override
  String get addressesAdd => 'Ajouter une adresse';

  @override
  String get addressesEdit => 'Modifier l’adresse';

  @override
  String get addressesEmpty =>
      'Aucune adresse enregistrée. Ajoutez-en une pour la livraison et les demandes.';

  @override
  String get addressesLabel => 'Libellé';

  @override
  String get addressesLine1 => 'Rue / bâtiment';

  @override
  String get addressesLine2 => 'Appartement / étage';

  @override
  String get addressesCity => 'Ville';

  @override
  String get addressesDistrict => 'Quartier / zone';

  @override
  String get addressesNotes => 'Notes de livraison';

  @override
  String get addressesOptional => 'facultatif';

  @override
  String get addressesSave => 'Enregistrer l’adresse';

  @override
  String get addressesSetDefault => 'Adresse par défaut';

  @override
  String get addressesDefaultBadge => 'Par défaut';

  @override
  String get addressesDeleteTitle => 'Supprimer l’adresse ?';

  @override
  String get addressesDeleteBody =>
      'Cette adresse sera retirée de votre profil.';

  @override
  String get addressesDeleteConfirm => 'Supprimer';

  @override
  String get addressesRequiredFields =>
      'Le libellé, la rue et la ville sont requis.';

  @override
  String get addressesPickTitle => 'Livrer à';

  @override
  String get aboutObicBlurb =>
      'OBIC est plus que des services — une app sociale pour la vie en Chine : discussions, Moments, repas, hôtels, santé et voyages.';

  @override
  String get aboutCredit => 'Réalisé par Dr Ali';

  @override
  String get languageToggle => 'Français';

  @override
  String get authLogin => 'Connexion';

  @override
  String get authRegister => 'Inscription';

  @override
  String get authEmailTab => 'E-mail';

  @override
  String get authPhoneTab => 'Téléphone';

  @override
  String get authUseSmsCode => 'Se connecter par code SMS';

  @override
  String get authUsePassword => 'Se connecter par mot de passe';

  @override
  String get authSendCode => 'Envoyer le code';

  @override
  String get authSmsCodeHint =>
      'Les nouveaux numéros sont inscrits automatiquement';

  @override
  String get authUseEmail => 'Utiliser l’e-mail';

  @override
  String get authUsePhone => 'Utiliser le téléphone';

  @override
  String get authEmail => 'E-mail';

  @override
  String get authPhone => 'Téléphone';

  @override
  String get authName => 'Nom complet';

  @override
  String get authPassword => 'Mot de passe';

  @override
  String get authPasswordHint => 'Au moins 8 caractères';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authCreateAccount => 'Créer un compte';

  @override
  String get authLogout => 'Se déconnecter';

  @override
  String get authOrContinue => 'Ou continuer avec';

  @override
  String get authContinueGoogle => 'Continuer avec Google';

  @override
  String get authContinueApple => 'Continuer avec Apple';

  @override
  String get authSocialNotConfigured =>
      'La connexion Google ou Apple n\'est pas encore configurée sur cette version.';

  @override
  String get authProviderEmailNotVerified =>
      'Apple ou Google n\'a pas confirmé cet e-mail, donc OBIC ne saute pas la vérification.';

  @override
  String get authSocialRoleNotAllowed =>
      'Cet e-mail est un compte staff. Connectez-vous avec votre mot de passe.';

  @override
  String get authInvalidSocialToken =>
      'Cette connexion Google ou Apple n\'a pas pu être vérifiée. Réessayez.';

  @override
  String get authComingSoon => 'Bientôt';

  @override
  String get authEmailRequired => 'Saisissez votre e-mail';

  @override
  String get authPhoneRequired => 'Saisissez votre téléphone';

  @override
  String get authFailed => 'Connexion impossible';

  @override
  String get authTotpHint =>
      'Saisissez le code à 6 chiffres de votre application Authenticator';

  @override
  String get authTotpCode => 'Code Authenticator';

  @override
  String get authTotpVerify => 'Vérifier';

  @override
  String get authTotpBack => 'Retour à la connexion';

  @override
  String get authNetworkError =>
      'Erreur réseau — vérifiez la connexion et réessayez';

  @override
  String get authServerWaking =>
      'Le serveur démarre — attendez quelques secondes et réessayez';

  @override
  String get authStillConnecting =>
      'Connexion en cours — le serveur est peut-être en train de démarrer';

  @override
  String get authRequiredTitle => 'Connexion requise';

  @override
  String get authRequiredBody =>
      'La navigation est ouverte à tous. Pour demander un service, passer une commande, discuter, publier un Moment ou ajouter des amis, connectez-vous ou créez un compte.';

  @override
  String get authClose => 'Fermer';

  @override
  String get authWelcomeBack => 'Bon retour';

  @override
  String get authJoinHeadline => 'Rejoindre OBIC';

  @override
  String get authSignInSupport =>
      'Discuter avec des amis · Commander à manger · Réserver des hôtels · Santé et plus';

  @override
  String get authRegisterSupport =>
      'Discussions, Moments, repas, hôtels, santé et services OBIC — dans une seule app.';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authNoAccount => 'Nouveau ici ?';

  @override
  String get authHasAccount => 'Vous avez déjà un compte ?';

  @override
  String get authGoRegister => 'Créer un compte';

  @override
  String get authGoLogin => 'Se connecter';

  @override
  String get actionRequestService => 'Demander ce service';

  @override
  String get actionPlaceOrder => 'Passer une commande';

  @override
  String get actionChatStaff => 'Discuter avec l’équipe';

  @override
  String get obicAiTitle => 'OBIC AI';

  @override
  String get obicAiWelcome =>
      'Posez une question sur n’importe quel service de l’app — immobilier, transport, voyage, santé, restauration, shopping, éducation, logistique, administration, business, visas, hôtels, offres ou agences — ou sur le suivi de votre demande. L’équipe peut toujours aider.';

  @override
  String get obicAiInputHint => 'Demander à OBIC AI…';

  @override
  String get obicAiOfflineHint =>
      'OBIC AI est désactivé sur ce serveur tant que l’équipe ne l’active pas. Vous pouvez toujours écrire à l’équipe.';

  @override
  String get obicAiEmptyReply =>
      'Pas encore de réponse — réessayez ou écrivez à l’équipe.';

  @override
  String get obicAiTabInstructions => 'Guide';

  @override
  String get obicAiTabChat => 'Discussion';

  @override
  String get obicAiTabHistory => 'Historique';

  @override
  String get obicAiNewChat => 'Nouvelle discussion';

  @override
  String get obicAiHistoryEmpty =>
      'Aucune discussion passée. Posez une question dans Discussion — elle apparaîtra ici.';

  @override
  String get obicAiHistoryOpen => 'Ouvrir';

  @override
  String get obicAiHistoryDelete => 'Supprimer';

  @override
  String get obicAiCopy => 'Copier';

  @override
  String get obicAiCopied => 'Copié';

  @override
  String get obicAiNothingToCopy => 'Aucun texte à copier';

  @override
  String get obicAiRetry => 'Régénérer';

  @override
  String get obicAiStop => 'Arrêter';

  @override
  String get obicAiAttach => 'Joindre';

  @override
  String get obicAiAttachPhoto => 'Photo';

  @override
  String get obicAiAttachPdf => 'PDF';

  @override
  String get obicAiAttachSheet => 'Tableur';

  @override
  String get obicAiRemoveAttachment => 'Retirer la pièce jointe';

  @override
  String get obicAiFileTooLarge =>
      'Ce fichier dépasse 4 Mo. Choisissez-en un plus petit.';

  @override
  String get obicAiUnsupportedFile =>
      'Seules les photos JPEG, PNG ou WebP, les PDF et les tableurs Excel ou CSV sont acceptés.';

  @override
  String get obicAiAttachmentNotConfigured =>
      'La lecture des images et des fichiers n’est pas configurée.';

  @override
  String get obicAiCouldNotReadFile => 'Impossible de lire ce fichier.';

  @override
  String get obicAiInstructionsTitle => 'Comment utiliser OBIC AI';

  @override
  String get obicAiInstructionsBody =>
      'Ce que fait OBIC AI\n• Répond sur tout le catalogue Services — immobilier, transport, voyage, santé, restauration, shopping, éducation, logistique, démarches administratives et business — y compris visas, hôtels et livraison, ainsi que les offres et les agences.\n• Répond dans votre langue — arabe, anglais, chinois, français et d’autres. Écrivez naturellement ; il vous suit.\n\nCet écran et la réponse automatique\n• L’onglet Discussion est votre assistant. L’historique garde les questions et réponses pour y revenir plus tard.\n• Les discussions d’assistance et de commande peuvent aussi recevoir une courte réponse automatique.\n• Les discussions entre amis restent privées — pas d’IA.\n\nParler à l’équipe\n• Pour une personne : Messages → Assistance OBIC ou une discussion de commande → Parler à l’équipe.\n\nLangues\n• La langue de l’app (AR / EN / 中文 / FR) contrôle les libellés de cet écran.\n• La langue de votre message contrôle la réponse de l’IA.';

  @override
  String obicAiBalance(String amount) {
    return 'Solde : $amount';
  }

  @override
  String get obicAiTopUp => 'Recharger';

  @override
  String get obicAiTopUpTitle => 'Recharger OBIC AI';

  @override
  String get obicAiTopUpBody =>
      'Payez d’abord ¥200. Cette somme devient votre solde. Chaque usage débite ensuite un petit montant : texte ¥0.10, photo ¥0.20, PDF ou tableur ¥0.20. Si le solde ne couvre pas l’usage suivant, OBIC AI refuse jusqu’à un nouveau pack de ¥200.';

  @override
  String get obicAiSandboxTopUp => 'Confirmer le rechargement bac à sable ¥200';

  @override
  String get obicAiSandboxNote =>
      'Bac à sable : aucun argent réel n’est débité.';

  @override
  String get obicAiTopUpSuccess =>
      '¥200 ont été ajoutés à votre solde (bac à sable).';

  @override
  String get obicAiBalanceLow =>
      'Solde insuffisant. Rechargez un pack de ¥200 pour continuer.';

  @override
  String get obicAiTopUpFailed => 'Rechargement impossible. Réessayez.';

  @override
  String get obicAiCardNotConnected =>
      'Le paiement par carte n’est pas encore connecté.';

  @override
  String get msgTranslate => 'Traduire';

  @override
  String get msgShowOriginal => 'Voir l’original';

  @override
  String get msgShowTranslation => 'Voir la traduction';

  @override
  String get msgTranslating => 'Traduction…';

  @override
  String get msgTranslateFailed => 'Traduction impossible — réessayez.';

  @override
  String get authSuccessContinue => 'Connecté — vous pouvez continuer.';

  @override
  String get brandTag => 'Discussions · Repas · Hôtels · Santé et plus';

  @override
  String get searchPlaceholder => 'Rechercher repas, hôtels, santé, visas…';

  @override
  String get featured => 'À la une';

  @override
  String get vipTrip => 'Voyage VIP en Chine';

  @override
  String get vipTripDesc =>
      'Accueil à l’aéroport · Hôtels · Visites d’usines · Un responsable dédié';

  @override
  String get bookPkg => 'Réserver le forfait →';

  @override
  String get fastTrack => 'Voie rapide';

  @override
  String get visaExpress => 'Visa express';

  @override
  String get visaExpressDesc =>
      'Aide visa affaires et tourisme, avec liste et conseiller';

  @override
  String get from120 => 'À partir de 120 \$ →';

  @override
  String get setup => 'Mise en place';

  @override
  String get openBank => 'Ouvrir un compte bancaire';

  @override
  String get openBankDesc =>
      'Accompagnement pour un compte local, avec la succursale';

  @override
  String get startReq => 'Commencer la demande →';

  @override
  String get topServices => 'Services principaux';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get recommended => 'Recommandé';

  @override
  String get regionDetecting => 'Détection de votre région…';

  @override
  String get regionRefresh => 'Actualiser';

  @override
  String get regionUnavailable => 'Indisponible dans cette région';

  @override
  String get nearMeTitle => 'Succursales près de vous';

  @override
  String get nearMeHint => 'Triées par distance depuis votre position';

  @override
  String get allServices => 'Tous les services';

  @override
  String get serviceLabel => 'Service';

  @override
  String get officialBadge => 'OBIC officiel';

  @override
  String get includedTitle => 'Ce qui est inclus';

  @override
  String get advisorTitle => 'Conseiller dédié';

  @override
  String get advisorDesc => 'Attribué après l’envoi de votre demande';

  @override
  String get checklistTitle => 'Liste des documents';

  @override
  String get checklistDesc => 'Étapes claires dans votre demande';

  @override
  String get statusUpdatesTitle => 'Suivi';

  @override
  String get statusUpdatesDesc => 'Suivez l’avancement dans Demandes';

  @override
  String get requestSvc => 'Demander ce service';

  @override
  String get chatSupport => 'Assistance';

  @override
  String get chatComingSoon => 'Ouverture de l’assistance…';

  @override
  String get requestTitle => 'Demande';

  @override
  String get prefBranch => 'Succursale préférée';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint => 'Dates, objectifs, documents…';

  @override
  String get submitOrder => 'Envoyer la demande';

  @override
  String get orderSubmitted => 'Demande envoyée.';

  @override
  String get ordersEmptyGuest => 'Connectez-vous pour voir vos demandes.';

  @override
  String get ordersEmptyAuth =>
      'Aucune demande — demandez un service depuis l’accueil ou écrivez à l’équipe OBIC.';

  @override
  String get statusSubmitted => 'Envoyée';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusAssigned => 'Assignée';

  @override
  String get statusWaitingCustomer => 'En attente de vous';

  @override
  String get statusCompleted => 'Terminée';

  @override
  String get statusCancelled => 'Annulée';

  @override
  String get statusOpen => 'Ouverte';

  @override
  String get statusWithAgent => 'Avec un agent';

  @override
  String get requestTypeSupport => 'Assistance OBIC';

  @override
  String get orderChat => 'Discuter de cette demande';

  @override
  String get legalTerms => 'Conditions';

  @override
  String get legalPrivacy => 'Politique de confidentialité';

  @override
  String get legalAgreePrefix => 'En créant un compte, vous acceptez les';

  @override
  String get legalAnd => 'et';

  @override
  String get offlineBanner => 'En attente du réseau…';

  @override
  String get offlineConnecting => 'Connexion…';

  @override
  String get offlineNeedsNetwork =>
      'Vous êtes hors ligne — réessayez une fois connecté.';

  @override
  String get offlineNoInternet =>
      'Pas de connexion Internet. Vérifiez les réglages réseau';

  @override
  String get msgWaitingNetwork => 'En attente du réseau…';

  @override
  String get msgTapToResend => 'Touchez pour renvoyer';

  @override
  String get networkUnavailable => 'Réseau indisponible. Réessayez.';

  @override
  String get actionOk => 'OK';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get chatDayToday => 'Aujourd’hui';

  @override
  String get chatDayYesterday => 'Hier';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsGeneral => 'Général';

  @override
  String get settingsFeatures => 'Fonctions';

  @override
  String get settingsProfile => 'Profil';

  @override
  String get settingsAccountSecurity => 'Sécurité du compte';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsMomentsNotifications => 'Notifications Moments';

  @override
  String get settingsMomentsNotifyFriends =>
      'Me prévenir quand des amis publient des Moments';

  @override
  String get settingsMomentsMute => 'Mettre les Moments en sourdine';

  @override
  String get settingsInterface => 'Langue et affichage';

  @override
  String get settingsFriendsPermissions => 'Autorisations des amis';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String get settingsChats => 'Discussions';

  @override
  String get settingsVoiceVideo => 'Appels vocaux et vidéo';

  @override
  String get profileName => 'Nom';

  @override
  String get profilePhoto => 'Photo de profil';

  @override
  String get profileGender => 'Genre';

  @override
  String get profileGenderMale => 'Homme';

  @override
  String get profileGenderFemale => 'Femme';

  @override
  String get profileGenderOther => 'Autre';

  @override
  String get profileGenderUnset => 'Non défini';

  @override
  String get profileRegion => 'Région';

  @override
  String get profileMobile => 'Numéro de mobile';

  @override
  String get profileWhatsUp => 'Quoi de neuf';

  @override
  String get profileWhatsUpHint =>
      'Une courte ligne de statut que vos amis voient sur votre album';

  @override
  String get profileMyQr => 'Mon code QR';

  @override
  String get profileId => 'ID';

  @override
  String get momentsPin => 'Épingler';

  @override
  String get profilePhone => 'Téléphone';

  @override
  String get profileEmail => 'E-mail';

  @override
  String get profileCity => 'Ville';

  @override
  String get profileCountry => 'Pays';

  @override
  String get profileEmailReadOnly => 'L’e-mail ne peut pas être modifié ici';

  @override
  String get profileSave => 'Enregistrer';

  @override
  String get profileSaved => 'Profil enregistré';

  @override
  String get securityChangePassword => 'Changer le mot de passe';

  @override
  String get securityCurrentPassword => 'Mot de passe actuel';

  @override
  String get securityNewPassword => 'Nouveau mot de passe';

  @override
  String get securityPasswordChanged => 'Mot de passe mis à jour';

  @override
  String get securityLinkedAccounts => 'Connexions liées';

  @override
  String get friendsMuteMoments => 'Ne pas voir ses Moments';

  @override
  String get friendsMuteMomentsHint =>
      'Masquer ses Moments de votre fil et arrêter les badges et notifications';

  @override
  String get friendsHideMyMoments => 'Ne pas lui montrer mes Moments';

  @override
  String get friendsNoFriends => 'Pas encore d’amis';

  @override
  String get storageClearCache => 'Effacer le cache';

  @override
  String get storageCleared => 'Cache effacé';

  @override
  String get storageCacheHint =>
      'Retire les photos et fichiers en cache. Les discussions et la connexion restent.';

  @override
  String get storageClearConfirm =>
      'Effacer les photos et fichiers en cache sur ce téléphone ? Les discussions et la connexion restent.';

  @override
  String storageFreed(String size) {
    return '$size libérés';
  }

  @override
  String get storageImages => 'Images';

  @override
  String get storageVideos => 'Vidéos';

  @override
  String get storageVoice => 'Voix';

  @override
  String get storageFiles => 'Fichiers';

  @override
  String get storageMusic => 'Musique téléchargée';

  @override
  String get storageChats => 'Discussions';

  @override
  String get storageChatsHint =>
      'Conservées sur ce téléphone. Effacer le cache ne les retire pas.';

  @override
  String get storageClearMusic => 'Effacer la musique téléchargée';

  @override
  String get storageAutoDelete => 'Supprimer le cache ancien';

  @override
  String get storageAutoNever => 'Jamais';

  @override
  String storageAutoDays(int days) {
    return '$days jours';
  }

  @override
  String get chatsEnterSend => 'Entrée pour envoyer';

  @override
  String get chatsConfirmDelete => 'Demander avant de supprimer des messages';

  @override
  String get voiceSpeakerDefault =>
      'Haut-parleur par défaut pour les appels vocaux';

  @override
  String get voiceVideoPreview => 'Afficher mon aperçu vidéo';

  @override
  String get settingsSaved => 'Enregistré';

  @override
  String get switchAccountTitle => 'Changer de compte';

  @override
  String get switchAccountHint =>
      'Touchez la photo de profil pour changer de compte';

  @override
  String get switchAccountAdd => 'Ajouter un compte';

  @override
  String get momentsCopyLink => 'Copier le lien';

  @override
  String get momentsCopied => 'Lien copié';

  @override
  String get momentsCopyText => 'Copier';

  @override
  String get momentsTextCopied => 'Copié';

  @override
  String get momentsTranslate => 'Traduire';

  @override
  String get momentsMyAlbum => 'Mes Moments';

  @override
  String momentsFriendAlbum(String name) {
    return 'Moments de $name';
  }

  @override
  String get momentsCoverTapHint => 'Touchez la couverture pour la changer';

  @override
  String get momentsCoverAdjust => 'Ajuster la couverture';

  @override
  String get momentsCoverSave => 'Terminé';

  @override
  String get momentsCoverAdjustHint =>
      'Glissez pour déplacer · pincez pour zoomer · puis touchez Terminé';

  @override
  String get channelTitle => 'Chaînes';

  @override
  String get callErrorGeneric => 'Connexion impossible — réessayez';

  @override
  String get callErrorPermission =>
      'L’autorisation de la caméra ou du micro est requise';

  @override
  String get callErrorJoin =>
      'L’appel n’a pas pu démarrer — vérifiez le réseau et réessayez';

  @override
  String get settingsSystem => 'Système';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsSupportSafety => 'Assistance et sécurité';

  @override
  String get settingsContactSupport => 'Contacter l’assistance';

  @override
  String get settingsReportBug => 'Signaler un problème';

  @override
  String get settingsRestoreAccount => 'Restaurer le compte';

  @override
  String get restoreAccountHint =>
      'Demandez à l’équipe OBIC de restaurer un compte désactivé depuis l’Admin';

  @override
  String get restoreAccountDialog =>
      'Il n’y a pas de restauration en libre-service. Contactez l’assistance OBIC avec votre e-mail ou téléphone — un SuperAdmin ou l’équipe Ops peut restaurer votre compte depuis l’Admin. Ensuite, connectez-vous avec le même mot de passe.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountBody =>
      'Votre compte sera désactivé. Vous serez déconnecté et retiré de cet appareil. L’équipe peut le restaurer depuis l’Admin si besoin.';

  @override
  String get deleteAccountPasswordRequired => 'Mot de passe actuel (requis)';

  @override
  String get deleteAccountSuperAdminRule =>
      'SuperAdmin : vous ne pouvez supprimer ce compte que si un autre SuperAdmin existe encore. Le dernier SuperAdmin ne peut pas se supprimer.';

  @override
  String get deleteAccountConfirm => 'Supprimer';

  @override
  String get deleteAccountDone => 'Compte supprimé sur cet appareil';

  @override
  String get reportBugTitle => 'Signaler un problème';

  @override
  String get reportBugDescriptionHint =>
      'Décrivez ce qui s’est passé (5 caractères ou plus)';

  @override
  String get reportBugAddPhotos => 'Ajouter des photos';

  @override
  String get reportBugSubmit => 'Envoyer';

  @override
  String get reportBugThanks =>
      'Merci — notre équipe examinera votre signalement';

  @override
  String get reportBugTooShort => 'Ajoutez un peu plus de détails';

  @override
  String get themeSystem => 'Comme le système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get chatMute => 'Mettre les notifications en sourdine';

  @override
  String get chatUnmute => 'Réactiver les notifications';

  @override
  String get chatMuted => 'Discussion en sourdine';

  @override
  String get chatUnmuted => 'Notifications réactivées';

  @override
  String get chatHide => 'Masquer la discussion';

  @override
  String get chatHideConfirm =>
      'Masquer cette discussion de votre liste ? La rouvrir la fera revenir.';

  @override
  String get chatClearHistory => 'Effacer l’historique';

  @override
  String get chatClearHistoryConfirm =>
      'Effacer les messages de cette discussion pour vous ? Cette action est définitive.';

  @override
  String get chatDelete => 'Supprimer la discussion';

  @override
  String get chatDeleteConfirm =>
      'Supprimer cette discussion de votre liste et effacer l’historique pour vous ?';

  @override
  String get chatMarkUnread => 'Marquer comme non lu';

  @override
  String get chatPin => 'Épingler en haut';

  @override
  String get chatUnpin => 'Désépingler';

  @override
  String get chatDraftPrefix => '[Brouillon]';

  @override
  String get chatRecall => 'Retirer';

  @override
  String get chatRecalledYou => 'Vous avez retiré un message';

  @override
  String get chatRecalledPeer => 'Un message a été retiré';

  @override
  String get errorProfileFieldsUnsupported =>
      'Impossible d’enregistrer le profil. Mettez l’app à jour et réessayez.';

  @override
  String get errorWrongPassword => 'Le mot de passe actuel est incorrect';

  @override
  String get errorEmailTaken => 'Cet e-mail est déjà utilisé';

  @override
  String get errorObicIdTaken => 'Cet ID OBIC est déjà pris';

  @override
  String get errorGenericRetry => 'Un problème est survenu — réessayez';

  @override
  String get errorUploadFailed =>
      'Impossible d’envoyer la photo — essayez une autre image';

  @override
  String get errorMomentsCoverFailed =>
      'Impossible de mettre à jour la couverture Moments — réessayez';

  @override
  String get errorOnlySecretaryCanUpdateStatus =>
      'Seul le secrétariat peut mettre à jour le statut';

  @override
  String get profileObicIdCopied => 'ID OBIC copié';

  @override
  String get profileSetObicId => 'Définir l’ID OBIC';

  @override
  String get profileChangeObicId => 'Changer l’ID';

  @override
  String get profileEmailPasswordRequired =>
      'Mot de passe actuel (pour changer l’e-mail)';

  @override
  String get profileEmailChangeHint =>
      'Changer l’e-mail exige votre mot de passe. L’ancien e-mail ne pourra plus se connecter.';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get verifyOtpTitle => 'Saisir le code de vérification';

  @override
  String get verifyOtpEmailHint =>
      'Nous avons envoyé un code à 6 chiffres à votre e-mail';

  @override
  String get verifyOtpPhoneHint =>
      'Nous avons envoyé un code à 6 chiffres à votre téléphone';

  @override
  String get verifyOtpPhoneViaEmailHint =>
      'Pour l’instant le code est envoyé à votre e-mail. La vérification SMS viendra plus tard.';

  @override
  String get verifyOtpPhoneTrialEmailHint =>
      'Pour l’instant le code est envoyé à votre e-mail. La vérification SMS viendra plus tard.';

  @override
  String get verifyOtpPhoneTrialLogHint =>
      'Saisissez le code de vérification reçu par e-mail';

  @override
  String get verifyOtpSmsNotConfigured =>
      'Les SMS ne sont pas encore configurés. Réessayez plus tard ou contactez l’assistance';

  @override
  String get verifyOtpSmsSendFailed =>
      'Impossible d’envoyer le SMS. Réessayez dans un instant';

  @override
  String get verifyOtpEmailSendFailed =>
      'Impossible d’envoyer le code par e-mail. Vérifiez l’adresse et réessayez';

  @override
  String get verifyOtpEmailRequiredForPhone =>
      'Ajoutez une adresse e-mail pour recevoir le code de vérification';

  @override
  String get verifyOtpInvalid => 'Saisissez le code à 6 chiffres';

  @override
  String get verifyOtpWrongCode => 'Code invalide';

  @override
  String get verifyOtpExpired => 'Code expiré — demandez-en un nouveau';

  @override
  String get verifyOtpTooManyAttempts =>
      'Trop de tentatives — demandez un nouveau code';

  @override
  String get verifyOtpSessionExpired =>
      'Session de vérification expirée — recommencez';

  @override
  String get verifyOtpConfirm => 'Vérifier';

  @override
  String get verifyOtpResend => 'Renvoyer le code';

  @override
  String verifyOtpResendIn(Object seconds) {
    return 'Renvoyer dans $seconds s';
  }

  @override
  String get verifyOtpResent => 'Code envoyé';

  @override
  String verifyOtpTrialCode(Object code) {
    return 'Code d’essai : $code';
  }

  @override
  String get friendsCopyObicId => 'Copier l’ID OBIC';

  @override
  String get phoneVerifyTitle => 'Vérifier le téléphone';

  @override
  String get phoneVerifyHeadline => 'Mobile chinois requis';

  @override
  String get phoneVerifyBody =>
      'En Chine, ajoutez et vérifiez un numéro mobile continental (+86) avant d’utiliser les discussions et les demandes. Les réglages et la langue restent disponibles.';

  @override
  String get phoneVerifyBodyEmailOtp =>
      'Saisissez votre mobile continental (+86). Pour l’instant nous le vérifions par e-mail ; les SMS viendront plus tard.';

  @override
  String get phoneVerifyEmailForCodeHint =>
      'E-mail pour le code de vérification';

  @override
  String get phoneVerifySendCode => 'Envoyer le code de vérification';

  @override
  String get phoneVerifyOpenSettings => 'Langue et apparence';

  @override
  String get phoneVerifyLater => 'Activer plus tard';

  @override
  String get phoneVerifyLocked =>
      'Vous pouvez regarder. Activez le numéro avant d’agir.';

  @override
  String get phoneVerifyActivate => 'Activer le numéro';

  @override
  String get phoneChinaOnly =>
      'Numéros de Chine continentale seulement (+86 / 1[3-9]…)';

  @override
  String get smsPhoneCountries =>
      'Utilisez un mobile de Chine, d’Arabie saoudite ou du Yémen.';

  @override
  String get smsCountryChina => 'Chine +86';

  @override
  String get smsCountrySaudi => 'Arabie saoudite +966';

  @override
  String get smsCountryYemen => 'Yémen +967';

  @override
  String get phoneVerifyBlocked =>
      'Vérifiez votre mobile chinois pour continuer';

  @override
  String get emailVerifyTitle => 'Vérifier l’e-mail';

  @override
  String get emailVerifyHeadline => 'Vérification de l’e-mail requise';

  @override
  String get emailVerifyBody =>
      'En Chine, vérifiez votre e-mail avant d’utiliser les discussions et les demandes. Nous envoyons un code dans votre boîte.';

  @override
  String get emailVerifySendCode => 'Envoyer le code par e-mail';

  @override
  String get authChinaPhoneRequired =>
      'En Chine, inscrivez-vous avec un mobile continental (+86) et un e-mail pour le code';

  @override
  String get profileUseCurrentLocation => 'Utiliser la position actuelle';

  @override
  String get profileLocationDetecting => 'Détection de la position…';

  @override
  String profileLocationDetail(String detail) {
    return 'À proximité : $detail';
  }

  @override
  String get profilePickCountry => 'Choisir le pays';

  @override
  String get profilePickCity => 'Choisir la ville';

  @override
  String get profileSearchCountry => 'Rechercher un pays';

  @override
  String get profileSearchCity => 'Rechercher une ville';

  @override
  String get profileLocationFailed =>
      'Position introuvable — choisissez le pays et la ville';

  @override
  String get miniAppsTitle => 'Mini-apps';

  @override
  String get miniAppsPullCue => 'Tirez vers le bas pour les Mini-apps';

  @override
  String get miniAppsPullHint => 'Mini-apps approuvées';

  @override
  String get miniAppsTipTitle => 'Les Mini-apps sont ici';

  @override
  String get miniAppsTipBody =>
      'Tirez vers le bas depuis le haut de l’accueil, ou touchez la barre Mini-apps, pour ouvrir les mini-apps approuvées.';

  @override
  String get miniAppsTipTry => 'Essayer';

  @override
  String get miniAppsTipDismiss => 'Compris';

  @override
  String get miniAppsSearchHint => 'Rechercher des mini-apps';

  @override
  String get miniAppsEmptySearch => 'Aucune mini-app correspondante';

  @override
  String get miniAppsClose => 'Fermer';

  @override
  String get miniAppsCloseHint => 'Glissez vers le haut pour fermer';

  @override
  String get miniAppsExampleBadge => 'Ex.';

  @override
  String get miniAppsPartnerBadge => 'Mini-app d’exemple';

  @override
  String get miniAppsComingSoonBody =>
      'Seule une mini-app approuvée s’ouvre dans OBIC.';

  @override
  String get miniAppsPartnerHint =>
      'Envoyez une page depuis Réglages → Mini-apps. Après l’approbation du SuperAdmin, elle apparaît ici. Les pages refusées ou désactivées restent fermées.';

  @override
  String get channelDescription =>
      'Courtes vidéos de l’équipe OBIC et des amis';

  @override
  String get channelFollow => 'Suivre';

  @override
  String get channelFollowing => 'Abonné';

  @override
  String channelStats(int followers, int videos) {
    return '$followers abonnés · $videos vidéos';
  }

  @override
  String channelLimitsHint(int mb, int sec) {
    return 'Extraits jusqu’à $mb Mo et $sec secondes';
  }

  @override
  String get channelEmpty =>
      'Pas encore de vidéos — soyez le premier à en envoyer';

  @override
  String get channelUpload => 'Envoyer';

  @override
  String get channelUploadTitle => 'Envoyer une courte vidéo';

  @override
  String get channelUploadLimits => 'Max 40 Mo et 60 secondes';

  @override
  String get channelCaptionHint => 'Ajouter une légende (facultatif)';

  @override
  String get channelUploadDone => 'Vidéo publiée';

  @override
  String get channelVideoTooLarge => 'Vidéo trop lourde (max 40 Mo)';

  @override
  String get channelVideoTooLong => 'Vidéo trop longue (max 60 secondes)';

  @override
  String get channelNoCaption => 'Courte vidéo';

  @override
  String get discoverTitle => 'Découvrir';

  @override
  String get discoverMiniAppsHint =>
      'Ouvrir les mini-apps · ou tirer vers le bas sur l’accueil';

  @override
  String get channelTabFollow => 'Suivre';

  @override
  String get channelTabNearby => 'À proximité';

  @override
  String get channelTabFriends => 'Amis';

  @override
  String get channelTabHot => 'Tendances';

  @override
  String get channelMyChannel => 'Ma chaîne';

  @override
  String get channelOfficialShort => 'OBIC officiel';

  @override
  String get channelPostDenied =>
      'Seuls les amis peuvent voir les chaînes personnelles. L’équipe publie sur Officiel.';

  @override
  String get channelShared => 'Copié — le nombre de partages est mis à jour';

  @override
  String get channelShareTitle => 'Partager';

  @override
  String get channelShareToMoments => 'Partager dans Moments';

  @override
  String get channelShareToChat => 'Partager dans une discussion';

  @override
  String get channelShareCopyLink => 'Copier le lien';

  @override
  String get channelShareCopied => 'Lien copié';

  @override
  String get channelShareMomentsDone => 'Partagé dans Moments';

  @override
  String get channelShareChatDone => 'Envoyé dans la discussion';

  @override
  String get channelShareNoFriends =>
      'Ajoutez des amis pour partager dans une discussion';

  @override
  String get channelSharePickFriend => 'Envoyer à…';

  @override
  String channelCommentsTitle(int count) {
    return '$count commentaires';
  }

  @override
  String get channelCommentsEmpty => 'Pas encore de commentaires';

  @override
  String get channelCommentHint => 'Dites quelque chose…';

  @override
  String get chatNewChat => 'Nouvelle discussion';

  @override
  String get momentsUnpin => 'Désépingler';

  @override
  String get momentsPinnedToast => 'Épinglé en haut';

  @override
  String get momentsUnpinnedToast => 'Désépinglé';

  @override
  String get momentsHideTheirs => 'Ne pas voir ses Moments';

  @override
  String get momentsShowTheirs => 'Voir ses Moments';

  @override
  String get momentsHideMine => 'Masquer mes Moments';

  @override
  String get momentsShowMine => 'Lui montrer mes Moments';

  @override
  String get momentsPrefsSaved => 'Mis à jour';

  @override
  String get settingsSounds => 'Sons';

  @override
  String get soundCall => 'Sonnerie d’appel';

  @override
  String get soundMessage => 'Son des messages';

  @override
  String get soundNotification => 'Son des notifications';

  @override
  String get soundClassic => 'Classique';

  @override
  String get soundSoft => 'Doux';

  @override
  String get soundBright => 'Vif';

  @override
  String get friendsPickerSearch => 'Rechercher';

  @override
  String get friendsPickerEmpty => 'Aucun résultat';

  @override
  String get messagesFilterAll => 'Tout';

  @override
  String get messagesFilterUnread => 'Non lus';

  @override
  String get messagesFilterGroups => 'Groupes';

  @override
  String get messagesFilterServices => 'Services';

  @override
  String get messagesFilterEmpty => 'Aucune discussion dans cette vue';

  @override
  String get chatMarkRead => 'Marquer comme lu';

  @override
  String get messagesMarkAllRead => 'Tout marquer comme lu';

  @override
  String get messagesMarkAllReadDone =>
      'Toutes les discussions sont marquées comme lues';

  @override
  String get chatTimeYesterday => 'Hier';

  @override
  String get chatWeekdayMon => 'lun.';

  @override
  String get chatWeekdayTue => 'mar.';

  @override
  String get chatWeekdayWed => 'mer.';

  @override
  String get chatWeekdayThu => 'jeu.';

  @override
  String get chatWeekdayFri => 'ven.';

  @override
  String get chatWeekdaySat => 'sam.';

  @override
  String get chatWeekdaySun => 'dim.';

  @override
  String get messagesSwipeRead => 'Lu';

  @override
  String get messagesSwipeUnread => 'Non lu';

  @override
  String get messagesSwipePin => 'Épingler';

  @override
  String get messagesSwipeUnpin => 'Retirer';

  @override
  String get messagesSwipeMute => 'Sourdine';

  @override
  String get messagesSwipeUnmute => 'Son';

  @override
  String get messagesSearchHint => 'Rechercher';

  @override
  String get messagesSearchChats => 'Discussions';

  @override
  String get messagesSearchHistory => 'Historique des discussions';

  @override
  String messagesSearchRelated(int n) {
    return '$n messages associés';
  }

  @override
  String get messagesSearchEmpty => 'Aucun résultat';

  @override
  String get chatSearchHint => 'Rechercher dans la discussion';

  @override
  String get chatSearch => 'Rechercher';

  @override
  String get chatSearchEmpty => 'Aucun message correspondant';

  @override
  String chatSearchPosition(int current, int total) {
    return '$current/$total';
  }

  @override
  String get chatSearchOlder => 'Précédent';

  @override
  String get chatSearchNewer => 'Suivant';

  @override
  String get chatSearchPhotos => 'Photos';

  @override
  String get chatSearchVideos => 'Vidéos';

  @override
  String get chatSearchFiles => 'Fichiers';

  @override
  String get chatSearchLinks => 'Liens';

  @override
  String get chatSearchAll => 'Tout';

  @override
  String get chatFindInChat => 'Rechercher dans la discussion';

  @override
  String get chatUnreadNotInView =>
      'Le premier message non lu n’est pas dans l’historique chargé';

  @override
  String get chatCopy => 'Copier';

  @override
  String get chatQuote => 'Citer';

  @override
  String get chatDeleteForMe => 'Supprimer pour moi';

  @override
  String get chatDeleteForMeConfirm =>
      'Supprimer ce message uniquement sur cet appareil ?';

  @override
  String get chatCopied => 'Copié';

  @override
  String get chatNothingToCopy => 'Rien à copier';

  @override
  String get chatDeletedForMe => 'Supprimé pour vous';

  @override
  String get chatMessageActions => 'Actions du message';

  @override
  String get friendsContactsTitle => 'Contacts';

  @override
  String get friendsGroupChats => 'Discussions de groupe';

  @override
  String get friendsNewGroup => 'Nouveau groupe';

  @override
  String get friendsStarred => 'Favoris';

  @override
  String get directoryTitle => 'Annuaire';

  @override
  String get directoryHint =>
      'Les collègues que vous êtes autorisé à voir. Les téléphones restent chez le SuperAdmin.';

  @override
  String get directoryEmpty => 'Aucun collègue dans votre vue.';

  @override
  String get directorySearch => 'Rechercher un collègue';

  @override
  String get directoryUnassigned => 'Sans service';

  @override
  String get directoryMessage => 'Message';

  @override
  String get directoryLoadFailed => 'Impossible de charger l’annuaire';

  @override
  String get approvalsTitle => 'Approbations';

  @override
  String get approvalsHint =>
      'Envoyez une demande. Les approbateurs répondent dans l’ordre.';

  @override
  String get approvalsEmpty => 'Aucune demande.';

  @override
  String get approvalsNew => 'Nouvelle demande';

  @override
  String get approvalsTemplate => 'Modèle';

  @override
  String get approvalsTitleField => 'Titre';

  @override
  String get approvalsDetails => 'Détails';

  @override
  String get approvalsSend => 'Envoyer';

  @override
  String get approvalsApprove => 'Approuver';

  @override
  String get approvalsReject => 'Refuser';

  @override
  String get approvalsCancel => 'Annuler la demande';

  @override
  String get approvalsWaiting => 'En attente de vous';

  @override
  String get approvalsMine => 'Mes demandes';

  @override
  String get approvalsLoadFailed => 'Impossible de charger les approbations';

  @override
  String get approvalPending => 'En cours';

  @override
  String get approvalApproved => 'Approuvée';

  @override
  String get approvalRejected => 'Refusée';

  @override
  String get approvalCancelled => 'Annulée';

  @override
  String get attendanceTitle => 'Pointage';

  @override
  String get attendanceHint =>
      'Pointez à l’arrivée et au départ. Les heures suivent l’horloge de l’entreprise.';

  @override
  String get attendanceClockIn => 'Arrivée';

  @override
  String get attendanceClockOut => 'Départ';

  @override
  String get attendanceMissing => 'Non pointé';

  @override
  String get attendanceOnTime => 'À l’heure';

  @override
  String get attendanceLate => 'En retard';

  @override
  String get attendanceEarly => 'Parti tôt';

  @override
  String get attendanceOffDay => 'Hors horaire';

  @override
  String get attendanceRecent => 'Jours récents';

  @override
  String get attendanceNote => 'Note (facultatif)';

  @override
  String get attendanceLoadFailed => 'Impossible de charger le pointage';

  @override
  String get reportsTitle => 'Rapports';

  @override
  String get reportsHint =>
      'Écrivez ce qui est fait et la suite. Le jour, la semaine et le mois en cours peuvent être mis à jour.';

  @override
  String get reportsDaily => 'Quotidien';

  @override
  String get reportsWeekly => 'Hebdomadaire';

  @override
  String get reportsMonthly => 'Mensuel';

  @override
  String get reportsDone => 'Fait';

  @override
  String get reportsPlan => 'Suite';

  @override
  String get reportsBlockers => 'Blocages';

  @override
  String get reportsSend => 'Envoyer';

  @override
  String get reportsMissing => 'Non envoyé';

  @override
  String get reportsSent => 'Envoyé';

  @override
  String get reportsInbox => 'Reçus';

  @override
  String get reportsMine => 'Mes rapports';

  @override
  String get reportsNone => 'Aucun pour le moment.';

  @override
  String get reportsLoadFailed => 'Impossible de charger les rapports';

  @override
  String get formsTitle => 'Formulaires';

  @override
  String get formsHint =>
      'Remplissez un formulaire de l’entreprise. Le bureau lit ce que vous envoyez.';

  @override
  String get formsSend => 'Envoyer';

  @override
  String get formsFillRequired => 'Remplissez chaque champ obligatoire';

  @override
  String get formsNone => 'Aucun formulaire.';

  @override
  String get formsMine => 'Mes formulaires';

  @override
  String get formsLoadFailed => 'Impossible de charger les formulaires';

  @override
  String get collectionTitle => 'Formulaires de collecte';

  @override
  String get collectionHint =>
      'Remplissez le formulaire qui vous a été envoyé. Vous pouvez le modifier tant qu’il est ouvert.';

  @override
  String get collectionSend => 'Envoyer';

  @override
  String get collectionFillRequired => 'Remplissez chaque champ obligatoire';

  @override
  String get collectionNone => 'Aucun formulaire ne vous a été envoyé.';

  @override
  String get collectionOpen => 'Ouvert';

  @override
  String get collectionClosed => 'Clos';

  @override
  String get collectionLoadFailed =>
      'Impossible de charger les formulaires de collecte';

  @override
  String get roomsTitle => 'Salles de réunion';

  @override
  String get roomsHint =>
      'Réservez une salle. Le même créneau ne peut pas être pris deux fois.';

  @override
  String get roomsBook => 'Réserver';

  @override
  String get roomsPurpose => 'Objet';

  @override
  String get roomsStart => 'Début';

  @override
  String get roomsEnd => 'Fin';

  @override
  String get roomsPick => 'Choisir';

  @override
  String get roomsUpcoming => 'À venir';

  @override
  String get roomsNone => 'Aucune réservation sur cette période.';

  @override
  String get roomsCancel => 'Annuler';

  @override
  String get roomsLoadFailed => 'Impossible de charger les salles';

  @override
  String get rosterTitle => 'Arrivées et départs';

  @override
  String get rosterHint =>
      'Demandez à partir à votre dernier jour. La confirmation ne ferme pas la connexion.';

  @override
  String get rosterAsk => 'Demander à partir';

  @override
  String get rosterJoined => 'Arrivée';

  @override
  String get rosterLastDay => 'Dernier jour';

  @override
  String get rosterNote => 'Note';

  @override
  String get rosterActive => 'En poste';

  @override
  String get rosterLeaving => 'Départ demandé';

  @override
  String get rosterLeft => 'Parti';

  @override
  String get rosterUnrecorded => 'Non enregistré';

  @override
  String get rosterMissing =>
      'Votre date d’arrivée n’est pas encore au registre.';

  @override
  String get rosterPending => 'Votre demande de départ attend le bureau.';

  @override
  String get rosterRecorded =>
      'Votre départ est enregistré. La connexion reste ouverte jusqu’à ce que le bureau la ferme.';

  @override
  String get rosterLoadFailed => 'Impossible de charger le registre';

  @override
  String get payslipsTitle => 'Bulletins de paie';

  @override
  String get payslipsHint =>
      'Ouvrez votre bulletin et confirmez que vous l’avez vu. Cet enregistrement n’envoie pas d’argent.';

  @override
  String get payslipsSeen => 'Je l’ai vu';

  @override
  String get payslipsConfirmed => 'Vu';

  @override
  String get payslipsOpen => 'En attente';

  @override
  String get payslipsEarning => 'Salaire';

  @override
  String get payslipsDeduction => 'Retenue';

  @override
  String get payslipsNet => 'Net';

  @override
  String get payslipsNote => 'Note';

  @override
  String get payslipsNone => 'Aucun bulletin.';

  @override
  String get payslipsLoadFailed => 'Impossible de charger les bulletins';

  @override
  String get companyContactsTitle => 'Contacts clients';

  @override
  String get companyContactsHint =>
      'Ces contacts appartiennent à l’entreprise. Vous voyez les personnes qui vous sont assignées.';

  @override
  String get companyContactsName => 'Nom';

  @override
  String get companyContactsPhone => 'Téléphone';

  @override
  String get companyContactsOrg => 'Organisation';

  @override
  String get companyContactsNote => 'Note';

  @override
  String get companyContactsSave => 'Enregistrer';

  @override
  String get companyContactsNew => 'Nouveau contact';

  @override
  String get companyContactsActive => 'Actif';

  @override
  String get companyContactsPaused => 'En pause';

  @override
  String get companyContactsSearch => 'Rechercher';

  @override
  String get companyContactsNone => 'Aucun contact.';

  @override
  String get companyContactsLoadFailed =>
      'Impossible de charger les contacts clients';

  @override
  String get companyTagsTitle => 'Étiquettes clients';

  @override
  String get companyTagsHint =>
      'Étiquettes définies par l’entreprise. Les noms affichés sont les contacts qui vous sont assignés.';

  @override
  String get companyTagsActive => 'En usage';

  @override
  String get companyTagsPaused => 'En pause';

  @override
  String get companyTagsNone => 'Aucune étiquette.';

  @override
  String get companyTagsLoadFailed => 'Impossible de charger les étiquettes';

  @override
  String get companyGroupsTitle => 'Groupes clients';

  @override
  String get companyGroupsHint =>
      'Un ensemble de contacts de l’entreprise qui vous sont assignés. Ce n’est pas une discussion.';

  @override
  String get companyGroupsName => 'Groupe';

  @override
  String get companyGroupsNote => 'Note';

  @override
  String get companyGroupsSave => 'Enregistrer';

  @override
  String get companyGroupsNew => 'Nouveau groupe';

  @override
  String get companyGroupsActive => 'En usage';

  @override
  String get companyGroupsPaused => 'En pause';

  @override
  String get companyGroupsNone => 'Aucun groupe.';

  @override
  String get companyGroupsLoadFailed =>
      'Impossible de charger les groupes clients';

  @override
  String get companyWelcomesTitle => 'Messages de bienvenue';

  @override
  String get companyWelcomesHint =>
      'La formule à utiliser avec un nouveau client. L’application l’affiche et ne l’envoie pas.';

  @override
  String get companyWelcomesCopy => 'Copier';

  @override
  String get companyWelcomesCopied => 'Formule copiée';

  @override
  String get companyWelcomesAssigned => 'Assignée à vous';

  @override
  String get companyWelcomesDefault => 'Formule de l’entreprise';

  @override
  String get companyWelcomesNone => 'Aucune formule.';

  @override
  String get companyWelcomesLoadFailed => 'Impossible de charger la formule';

  @override
  String get quickRepliesTitle => 'Réponses rapides';

  @override
  String get quickRepliesHint =>
      'Copiez une réponse de l’entreprise, ou enregistrez la vôtre. L’application ne l’envoie pas.';

  @override
  String get quickRepliesName => 'Titre';

  @override
  String get quickRepliesBody => 'Réponse';

  @override
  String get quickRepliesSave => 'Enregistrer';

  @override
  String get quickRepliesNew => 'Nouvelle réponse';

  @override
  String get quickRepliesCopy => 'Copier';

  @override
  String get quickRepliesCopied => 'Réponse copiée';

  @override
  String get quickRepliesCompany => 'Entreprise';

  @override
  String get quickRepliesMine => 'Les miennes';

  @override
  String get quickRepliesActive => 'En usage';

  @override
  String get quickRepliesPaused => 'En pause';

  @override
  String get quickRepliesNone => 'Aucune réponse.';

  @override
  String get quickRepliesLoadFailed => 'Impossible de charger les réponses';

  @override
  String get companyHandoverTitle => 'Passation des clients';

  @override
  String get companyHandoverHint =>
      'Les passations qui vous donnent des contacts de l’entreprise, ou qui vous les retirent, sont listées ici. L’application n’écrit pas au client.';

  @override
  String companyHandoverFrom(String name) {
    return 'De $name';
  }

  @override
  String companyHandoverTo(String name) {
    return 'À $name';
  }

  @override
  String companyHandoverCount(int count) {
    return '$count contacts';
  }

  @override
  String get companyHandoverNone => 'Aucune passation.';

  @override
  String get companyHandoverLoadFailed =>
      'Impossible de charger les passations';

  @override
  String get companyDriveTitle => 'Fichiers de l’entreprise';

  @override
  String get companyDriveHint =>
      'Dossiers de l’entreprise. Ajoutez une photo depuis ce téléphone. Les autres fichiers s’ajoutent depuis le bureau du personnel. Un fichier ici n’est pas un lien public.';

  @override
  String get companyDriveNone => 'Aucun dossier.';

  @override
  String get companyDriveEmpty => 'Aucun fichier dans ce dossier.';

  @override
  String get companyDriveOpenOnDesk =>
      'Ouvrez ce fichier depuis le bureau du personnel.';

  @override
  String get companyDriveLoadFailed => 'Impossible de charger les fichiers';

  @override
  String get companyDocumentsTitle => 'Documents partagés';

  @override
  String get companyDocumentsHint =>
      'Ouvrez un document de l’entreprise et mettez le texte à jour. Le dernier enregistrement reste. Ce n’est pas un fichier du disque.';

  @override
  String get companyDocumentsBody => 'Texte';

  @override
  String get companyDocumentsSave => 'Enregistrer';

  @override
  String companyDocumentsSavedBy(String name) {
    return 'Dernier enregistrement par $name';
  }

  @override
  String get companyDocumentsNone => 'Aucun document.';

  @override
  String get companyDocumentsLoadFailed =>
      'Impossible de charger les documents';

  @override
  String get companySpreadsheetsTitle => 'Feuilles partagées';

  @override
  String get companySpreadsheetsHint =>
      'Ouvrez une feuille et modifiez les cellules. Le dernier enregistrement reste. Une cellule contient du texte, pas une formule.';

  @override
  String get companySpreadsheetsSave => 'Enregistrer';

  @override
  String companySpreadsheetsSavedBy(String name) {
    return 'Dernier enregistrement par $name';
  }

  @override
  String get companySpreadsheetsNone => 'Aucune feuille.';

  @override
  String get companySpreadsheetsLoadFailed =>
      'Impossible de charger les feuilles';

  @override
  String get companyCalendarTitle => 'Calendrier de l’entreprise';

  @override
  String get companyCalendarHint =>
      'Ajoutez un événement. Les heures sont à l’heure de la Chine. L’application n’envoie pas d’invitation. Ce n’est pas une réservation de salle.';

  @override
  String get companyCalendarName => 'Titre';

  @override
  String get companyCalendarDate => 'Date';

  @override
  String get companyCalendarStart => 'Début';

  @override
  String get companyCalendarEnd => 'Fin';

  @override
  String get companyCalendarNote => 'Note';

  @override
  String get companyCalendarSave => 'Enregistrer';

  @override
  String get companyCalendarNew => 'Nouvel événement';

  @override
  String get companyCalendarActive => 'Affiché';

  @override
  String get companyCalendarPaused => 'Masqué';

  @override
  String get companyCalendarNone => 'Aucun événement sur cette période.';

  @override
  String get companyCalendarLoadFailed => 'Impossible de charger le calendrier';

  @override
  String get companyMailTitle => 'Courrier de l’entreprise';

  @override
  String get companyMailHint =>
      'Envoyez un message aux autres employés. Il reste dans OBIC et n’est pas envoyé vers une boîte extérieure.';

  @override
  String get companyMailSubject => 'Objet';

  @override
  String get companyMailBody => 'Message';

  @override
  String get companyMailSend => 'Envoyer';

  @override
  String get companyMailTo => 'À';

  @override
  String get companyMailInbox => 'Boîte de réception';

  @override
  String get companyMailOutbox => 'Envoyés';

  @override
  String get companyMailNone => 'Aucun message.';

  @override
  String get companyMailLoadFailed => 'Impossible de charger le courrier';

  @override
  String get companyMeetingsTitle => 'Réunions de l’entreprise';

  @override
  String get companyMeetingsHint =>
      'Une réunion a une heure, un ordre du jour, les employés invités et des notes ensuite. L’heure est l’heure de Chine. L’application ne lance pas d’appel.';

  @override
  String get companyMeetingsName => 'Titre';

  @override
  String get companyMeetingsDate => 'Date';

  @override
  String get companyMeetingsStart => 'Début';

  @override
  String get companyMeetingsEnd => 'Fin';

  @override
  String get companyMeetingsAgenda => 'Ordre du jour';

  @override
  String get companyMeetingsNotes => 'Notes';

  @override
  String get companyMeetingsTo => 'Participants';

  @override
  String get companyMeetingsSave => 'Enregistrer';

  @override
  String get companyMeetingsNew => 'Nouvelle réunion';

  @override
  String get companyMeetingsActive => 'Affichée';

  @override
  String get companyMeetingsPaused => 'Masquée';

  @override
  String get companyMeetingsNone => 'Aucune réunion.';

  @override
  String get companyMeetingsLoadFailed => 'Impossible de charger les réunions';

  @override
  String get companyFileAnswersTitle => 'Réponses des documents';

  @override
  String get companyFileAnswersHint =>
      'Posez une question sur les documents partagés. La réponse vient uniquement de ces documents. Quand l’IA de l’entreprise est activée, elle rédige la réponse à partir des passages trouvés.';

  @override
  String get companyFileAnswersQuestion => 'Question';

  @override
  String get companyFileAnswersAsk => 'Demander';

  @override
  String get companyFileAnswersFromDocuments => 'Depuis les documents';

  @override
  String get companyFileAnswersFromAi => 'Depuis l’IA de l’entreprise';

  @override
  String get companyFileAnswersNone => 'Aucune question.';

  @override
  String get companyFileAnswersLoadFailed =>
      'Impossible de charger les réponses';

  @override
  String get companyAppsTitle => 'Applications de l’entreprise';

  @override
  String get companyAppsHint =>
      'Ouvrez un outil web de l’entreprise. La page reste sur son propre site.';

  @override
  String get companyAppsNone => 'Aucune application.';

  @override
  String get companyAppsLoadFailed => 'Impossible d’ouvrir l’application';

  @override
  String get friendsStar => 'Ajouter aux favoris';

  @override
  String get friendsUnstar => 'Retirer des favoris';

  @override
  String get friendsMessage => 'Message';

  @override
  String get friendsRecent => 'Récents';

  @override
  String get friendsNewMark => 'Nouveau';

  @override
  String friendsContactsCount(int count) {
    return '$count contacts';
  }

  @override
  String get friendsGroupsEmpty => 'Aucune discussion de groupe';

  @override
  String get friendsStarredEmpty =>
      'Aucun favori. Appuyez longtemps sur un ami pour l’ajouter.';

  @override
  String get contactProfileYou => 'Vous';

  @override
  String get contactProfileRemark => 'Remarque';

  @override
  String get contactProfileSetRemark => 'Définir une remarque';

  @override
  String get contactProfileRemarkHint =>
      'Un nom visible seulement sur ce téléphone';

  @override
  String contactProfileRealName(String name) {
    return 'Nom : $name';
  }

  @override
  String get contactProfileVoice => 'Appel vocal';

  @override
  String get contactProfileVideo => 'Appel vidéo';

  @override
  String get contactProfileVoiceOrVideo => 'Appel vocal ou vidéo';

  @override
  String get contactProfileSaved => 'Enregistré';

  @override
  String get contactProfileViewPhoto => 'Voir la photo';

  @override
  String get contactProfileCallFailed => 'Impossible de lancer l’appel';

  @override
  String contactMomentsNone(String name) {
    return '$name n’a encore rien publié.';
  }

  @override
  String get contactMomentsNoneSelf => 'Vous n’avez encore rien publié.';

  @override
  String get settingsMiniApps => 'Mini-apps';

  @override
  String get settingsMiniAppsHint =>
      'Envoyez une mini-app sur le site OBIC. Le SuperAdmin l’approuve avant que les autres puissent l’ouvrir.';

  @override
  String get miniAppsWebsiteBody =>
      'Les mini-apps se déposent sur le site OBIC, pas dans Réglages. Connectez-vous avec votre compte OBIC, puis envoyez le nom, la description, l’icône et le fichier zip.';

  @override
  String get miniAppsOpenWebsite => 'Ouvrir le site OBIC';

  @override
  String get miniAppWebsiteName => 'Site OBIC';

  @override
  String get miniAppFormTitle => 'Proposer une mini-app';

  @override
  String get miniAppName => 'Nom';

  @override
  String get miniAppDescription => 'Courte description';

  @override
  String get miniAppIconUrl => 'URL de l’icône (HTTPS)';

  @override
  String get miniAppPickIcon => 'Choisir une image';

  @override
  String get miniAppIconUploading => 'Envoi de l’icône…';

  @override
  String get miniAppStartUrl => 'Adresse de la page (HTTPS)';

  @override
  String get miniAppSubmit => 'Envoyer';

  @override
  String get miniAppMySubmissions => 'Vos envois';

  @override
  String get miniAppEmptyMine => 'Vous n’avez pas encore envoyé de mini-app.';

  @override
  String get miniAppSubmitted =>
      'Envoyé. Statut : en attente, jusqu’à l’examen du SuperAdmin.';

  @override
  String get miniAppHttpsRequired =>
      'L’adresse de la page doit être une URL HTTPS.';

  @override
  String get miniAppPickPackage => 'Choisir le paquet';

  @override
  String get miniAppPackageRequired =>
      'Choisissez un fichier .zip avec index.html à la racine.';

  @override
  String get miniAppNameRequired =>
      'Indiquez un nom et une courte description.';

  @override
  String get miniAppServerUnavailable =>
      'Les mini-apps ne sont pas encore sur ce serveur. Le formulaire est prêt ; l’examen commencera après la mise à jour de l’API.';

  @override
  String get miniAppStatusPending => 'En attente';

  @override
  String get miniAppStatusApproved => 'Approuvée';

  @override
  String get miniAppStatusRejected => 'Refusée';

  @override
  String get miniAppStatusDisabled => 'Désactivée';

  @override
  String get miniAppReviewReason => 'Motif';

  @override
  String get miniAppEngineFail => 'Impossible d’ouvrir cette mini-app';

  @override
  String get miniAppEngineReload => 'Recharger';

  @override
  String get miniAppEngineRestart => 'Redémarrer la mini-app';

  @override
  String get miniAppEngineRetry => 'Réessayer';

  @override
  String get discoverShortcuts => 'Raccourcis';

  @override
  String get discoverTrending => 'Tendances';

  @override
  String get discoverOffers => 'Offres';

  @override
  String get discoverMusic => 'Musique';

  @override
  String get discoverNew => 'Nouveautés';

  @override
  String get discoverNewHint => 'Mini-apps et nouveautés';

  @override
  String get discoverEmpty => 'Rien à afficher pour le moment';

  @override
  String get servicesRecent => 'Récents';

  @override
  String get servicesRecentEmpty => 'Aucun service récent';

  @override
  String get servicesHeroTitle => 'La Chine et le monde';
}
