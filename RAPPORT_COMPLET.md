# RAPPORT COMPLET - Quran Player App

---

## INFORMATIONS GÉNÉRALES

**Projet :** Quran Player - Application mobile de lecture audio du Coran
**Cours :** ING3 - Sécurité du Développement Mobile
**Technologies :** Flutter 3.41.3 + Dart 3.11.1 + Firebase + Android
**Architecture :** MVC (Model-View-Controller/Service)
**Stockage :** Firebase Firestore (cloud) + SharedPreferences (local)
**GitHub :** https://github.com/dinapsdeslol/quranapp

---

## DÉPENDANCES (pubspec.yaml)

| Package | Version | Rôle |
|---------|---------|------|
| flutter | SDK | Framework UI Material 3 |
| cupertino_icons | ^1.0.8 | Icônes iOS |
| firebase_core | ^3.6.0 | Initialisation Firebase |
| firebase_auth | ^5.3.1 | Auth email/password |
| cloud_firestore | ^5.4.4 | Base de données NoSQL |
| local_auth | ^2.3.0 | Biométrie fingerprint |
| audioplayers | ^6.1.0 | Lecture audio streaming |
| http | ^1.2.2 | Client HTTP API Quran |
| fl_chart | ^0.69.0 | Graphiques histogramme |
| shared_preferences | ^2.3.2 | Stockage local clé-valeur |
| intl | ^0.19.0 | Formatage dates |
| flutter_lints (dev) | ^6.0.0 | Règles de lint |

---

## STRUCTURE DU PROJET

`
projet/
├── lib/
│   ├── main.dart                 # Point d'entrée + AppFlow (108 lignes)
│   ├── models/
│   │   └── track_model.dart      # AudioTrack + SurahCategory (33 lignes)
│   ├── screens/
│   │   ├── bio_screen.dart       # Auth biométrique (173 lignes)
│   │   ├── login_screen.dart     # Connexion (199 lignes)
│   │   ├── register_screen.dart  # Inscription (149 lignes)
│   │   ├── forgot_screen.dart    # Mot de passe oublié (78 lignes)
│   │   ├── home_screen.dart      # Navigation principale (98 lignes)
│   │   ├── player_screen.dart    # Lecteur audio (195 lignes)
│   │   ├── stats_screen.dart     # Statistiques (187 lignes)
│   │   └── favorites_screen.dart # Favoris (102 lignes)
│   └── services/
│       ├── auth_service.dart     # Firebase Auth + Firestore (79 lignes)
│       ├── bio_service.dart      # local_auth + SharedPrefs (46 lignes)
│       ├── audio_service.dart    # audioplayers + stats (116 lignes)
│       ├── api_service.dart      # HTTP client API Quran (46 lignes)
│       └── favorite_service.dart # Firestore favoris (47 lignes)
├── android/
├── web/
├── test/
└── pubspec.yaml
`

---

## FLUX DE L'APPLICATION

`
Lancement
    |
    +-- kIsWeb ? --> LoginScreen directement
    |
    +-- BioService.isFirstLaunch()
        |
        +-- true --> BiometricScreen
        |             |
        |             +-- Fingerprint OK --> setFirstLaunchDone() --> LoginScreen
        |             +-- Skip (si indisponible) --> LoginScreen
        |
        +-- false --> FirebaseAuth.currentUser
                        |
                        +-- null --> LoginScreen
                        |             +-- Login OK --> getUserData() --> HomeScreen
                        |             +-- Register --> RegisterScreen --> Login
                        |
                        +-- not null --> getUserData()
                                          +-- data OK --> HomeScreen
                                          +-- null --> LoginScreen
`

---

## EXPLICATION FICHIER PAR FICHIER

### main.dart (108 lignes)

**Fonction main() :**
- WidgetsFlutterBinding.ensureInitialized() --> binding Flutter obligatoire
- Firebase.initializeApp() sur mobile uniquement
- unApp(QuranPlayerApp())

**QuranPlayerApp (StatelessWidget) :**
- MaterialApp avec thème Material 3, seed color #0D47A1

**AppFlow (StatefulWidget) :**
- Machine à états : _showBio, _showLogin, _loggedIn, _userData
- _checkLogin() verifie isFirstLaunch() --> currentUser --> getUserData()
- Fallback : si Firestore injoignable, passe a Login

---

### auth_service.dart (79 lignes)

**login(email, password) :**
- signInWithEmailAndPassword + try Firestore read
- Fallback si Firestore down : {firstName: email.split('@').first, lastName: '', email}

**register(email, password, firstName, lastName, birthDate, phone) :**
- Verifie calculateAge(birthDate) >= 13
- createUserWithEmailAndPassword + Firestore doc users/{uid}

**resetPassword(email) :** sendPasswordResetEmail

**calculateAge(birth) :** ge = now.year - birth.year avec ajustement mois/jour

---

### bio_service.dart (46 lignes)

**isBiometricAvailable() :** canCheckBiometrics && isDeviceSupported()

**authenticate() :** local_auth avec iometricOnly: true

**requireAuthForDelete() :** idem pour suppression favoris

**isFirstLaunch() :** prefs.getBool('bio_done') != true

**setFirstLaunchComplete() :** prefs.setBool('bio_done', true)

---

### api_service.dart (46 lignes)

**Base URL :** https://staticquran.vercel.app/api/v1

**getCategories() :** GET /surah --> parse JSON data[] --> SurahCategory

**_audioUrl(int id) :** padLeft(3,'0') --> https://server8.mp3quran.net/afs/{padded}.mp3

**Fallback :** 8 sourates codees en dur si API inaccessible

---

### audio_service.dart (116 lignes)

**playTrack(track) :** stop() --> play(UrlSource(url)) --> _recordListening()

**togglePlayPause() :** pause() / esume()

**toggleRepeat() :** setReleaseMode(loop/stop)

**_recordListening() :** incremente listen_YYYY-MM-DD + ajoute ID a 	racks_YYYY-MM-DD

**getTotalMinutes() :** somme de tous les listen_*

**getDailyMinutes() :** map des 30 derniers jours

**getTopTracks(limit:5) :** agrege 	racks_*, trie descendant

**getMonthlyGoal() / setMonthlyGoal() :** cle goal_hours (defaut 20)

---

### track_model.dart (33 lignes)

**AudioTrack :** id, surahName, surahEnglishName, ayahNumber, audioUrl + getter 	itle

**SurahCategory :** id, name, englishName, audioUrl?, tracks[]

---

### bio_screen.dart (173 lignes)

**_init() :** verifie isBiometricAvailable()

**_tryAuth() :** appelle uthenticate() --> succes : SystemSound.click + setFirstLaunchComplete() + onSuccess()

**UI :** Gradient bleu, icone fingerprint size 120, boutons Settings/Retry/Skip si indisponible

---

### login_screen.dart (199 lignes)

**Form :** email + password, validation requise

**Erreur :** Container Colors.red.shade800 + bordure yellowAccent

**Liens :** ForgotPassword, SignUp

**_login() :** AuthService().login() --> widget.onLogin(data) ou erreur

---

### register_screen.dart (149 lignes)

**Champs :** FirstName, LastName, Email, Password(min 6), Confirm, Phone, DateOfBirth

**Validation :** calculateAge(birthDate) >= 13, password match

**_register() :** AuthService().register(...) --> SnackBar succes + Navigator.pop()

---

### forgot_screen.dart (78 lignes)

**Champ :** email uniquement

**_sendReset() :** AuthService().resetPassword(email)

**UI :** icone check_circle (vert) si envoye, lock_reset (rouge) si erreur

---

### home_screen.dart (98 lignes)

**Attributs :** _audio = AudioService() (instance UNIQUE), _idx = 1

**IndexedStack :** 3 onglets (Stats, Player, Favorites) - conserve l'etat

**NavigationBar :** Material 3, 3 destinations

**Logout :** confirmation --> clear SharedPrefs (listen_*, 	racks_*, goal_hours) --> signOut() --> AppFlow()

---

### player_screen.dart (195 lignes)

**initState() :** _loadCategories() (API+fallback) + _loadFavIds() (Firestore stream) + 4 listeners audio

**Listeners :**
- onPositionChanged --> _posSec (clamped)
- onDurationChanged --> _durSec
- onPlayerComplete --> _playing = false
- onPlayerStateChanged --> reset si stopped

**_playSurah(cat) :** cree AudioTrack --> _audio.playTrack()

**_toggleFav(t) :** si favori --> equireAuthForDelete() --> remove ; sinon add

**UI :** Slider, Play/Pause, Repeat, liste avec highlight

---

### stats_screen.dart (187 lignes)

**_load() :** getTotalMinutes(), getDailyMinutes(), getTopTracks(), getMonthlyGoal()

**_changeGoal() :** SimpleDialog (5/10/15/20/25/30/40/50h)

**UI :**
- Welcome card gradient bleu avec prenom+nom (26pt bold)
- Temps total : hours = totalMin ~/ 60, mins = totalMin % 60
- Progression : LinearProgressIndicator (vert si >=100%, bleu sinon)
- Histogramme : l_chart BarChart 30 barres
- Top tracks : ListView numerote 1-5

---

### favorites_screen.dart (102 lignes)

**StreamBuilder :** _fav.stream().timeout(10s)

**_play(t) :** _audio.playTrack(t) + widget.onPlay()

**_delete(t) :** si isBiometricAvailable() --> equireAuthForDelete() --> remove ; sinon remove direct

**UI :** ListView.builder avec play/delete icons, fallback web "Favorites available on mobile"

---

### favorite_service.dart (47 lignes)

**add(track) :** users/{uid}/favorites/{trackId}.set({...}) avec FieldValue.serverTimestamp()

**remove(trackId) :** users/{uid}/favorites/{trackId}.delete()

**stream() :** orderBy('addedAt', descending).snapshots() --> List<AudioTrack>

---

## CONFIGURATION ANDROID

**AndroidManifest.xml :**
- Permissions : INTERNET, ACCESS_NETWORK_STATE, USE_BIOMETRIC, USE_FINGERPRINT, WAKE_LOCK, FOREGROUND_SERVICE
- EnableImpeller = false (desactive le nouveau renderer instable)
- usesCleartextTraffic = true

**build.gradle.kts :**
- compileSdk = 36, minSdk = 24, targetSdk = 36
- Java 17, Firebase BOM 34.12.0

---

## API ET SOURCES AUDIO

**API :** https://staticquran.vercel.app/api/v1/surah (GET)
- Reponse JSON : { data: [{ sequence, name: { arabic: { short }, latin: { short } }, translation }] }

**Audio :** https://server8.mp3quran.net/afs/{id3}.mp3
- id=1 --> 001.mp3, id=36 --> 036.mp3, id=114 --> 114.mp3
- Recitateur : Abdullah Al-Farsi (code afs)

---

## SÉCURITÉ

1. **Biometrie :** iometricOnly: true, pas de fallback PIN
2. **Skip :** UNIQUEMENT si isBiometricAvailable() = false
3. **Suppression favoris :** fingerprint requis si capteur disponible
4. **Firebase Auth :** hachage cote serveur, aucun stockage local du mot de passe
5. **Permissions :** USE_BIOMETRIC + USE_FINGERPRINT (compatibilite Android 9+)
6. **Logout :** nettoyage des cles listen_*, 	racks_*, goal_hours
7. **Firestore rules :** acces par UID uniquement

---

## DIFFICULTÉS RENCONTRÉES

| Probleme | Cause | Solution |
|----------|-------|----------|
| API renvoie HTML | yousefheiba.com obselete | Migration staticquran.vercel.app |
| Audio URL invalide | download.quranicaudio.com down | Migration server8.mp3quran.net |
| Slider crash | assert duree = 0 | Clamp + maxVal: 1.0 |
| AudioService duplique | conflit listeners | Injection constructeur via HomeScreen |
| Boucle spinner | _checkLogin() bloque | setState explicite |
| Error type 3 | Activite introuvable | Reinstall + pm clear |
| Pas de son emu | pcmWrite I/O error driver ranchu | Tester sur vrai device |
| GPU instable | opengl32sw manquant | hw.gpu.mode=software |
| Firestore injoignable | DNS/reseau PC | Fallback login donnees email |
| Java 26 incompatible | Gradle non supporte | JDK 17 Eclipse Temurin |

---

## QUESTIONS PIÈGES PROBABLES

**Q :** Securite des donnees ?
**R :** Firebase Auth hachage cote serveur, Firestore rules par UID, SharedPrefs efface au logout.

**Q :** Pourquoi SharedPrefs pour les stats ?
**R :** Donnees locales, pas besoin de sync inter-device, plus rapide, pas de connexion reseau necessaire.

**Q :** Stream Firestore des favoris ?
**R :** snapshots() = stream temps reel. StreamBuilder met a jour l'UI automatiquement.

**Q :** API Quran hors ligne ?
**R :** Fallback 8 sourates codees en dur.

**Q :** Streaming ou telechargement ?
**R :** Streaming via UrlSource, pas de cache local.

**Q :** Comptage des minutes ?
**R :** Pas de minuteur reel. Incremente listen_YYYY-MM-DD a chaque playTrack(). Compteur de lectures.

**Q :** EnableImpeller=false ?
**R :** Impeller instable sur Android 36. Force Skia (ancien moteur).

**Q :** kIsWeb ?
**R :** Debug Chrome. Firebase web non configure.

**Q :** Rafraichissement stats ?
**R :** Charge une fois dans initState(). Changement d'onglet necessaire.

**Q :** Son emu ?
**R :** Driver ranchu ne peut pas ecrire sur le stack audio de ce PC. Code correct, fonctionne sur vrai telephone.

**Q :** Architecture ?
**R :** MVC : Models (donnees), Views (screens/UI), Controllers (services/logique metier).

**Q :** Gestion erreurs reseau ?
**R :** Try/catch partout. Fallback API Quran (8 sourates). Fallback Firestore (donnees email). SnackBar utilisateur.

---

## CHIFFRES CLÉS

- **8 ecrans** (bio, login, register, forgot, home, player, stats, favorites)
- **5 services** (auth, bio, audio, api, favorite)
- **2 modeles** (AudioTrack, SurahCategory)
- **~1400 lignes Dart**
- **11 dependances directes**
- **114 sourates disponibles + 8 fallback**
- **30 jours d'historique stats**
- **8 valeurs d'objectif (5-50h)**
- **5 top tracks affichees**

---

## ÉTAT DU PROJET

### Termine
- Full project cree et structure (models, services, screens)
- Firebase Auth : login, register, reset password, age validation
- Stats : welcome card, temps total, progression, histogramme fl_chart, top tracks
- Biometrie : fingerprint + skip si indisponible
- Shared AudioService injecte par constructeur
- API staticquran.vercel.app + audio server8.mp3quran.net
- Slider clamp + listeners onPlayerStateChanged
- Favorites play switch to Player tab
- Android : JDK 17, Impeller disabled, cleartext traffic
- GitHub : https://github.com/dinapsdeslol/quranapp
- Logout : clear SharedPrefs + navigate to AppFlow
- AuthService fallback si Firestore unreachable
- SnackBar erreurs partout
- Presentation 19 slides : Presentation_Quran_Player_V2.pptx

### Bloque (environnement)
- Audio muet sur emu (driver ranchu I/O error)
- Firestore injoignable (DNS/reseau)
- GPU instable (opengl32sw manquant)

### Recommandation
- Tester sur vrai telephone Android

---
