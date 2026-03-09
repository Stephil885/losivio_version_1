/*
lib/
├─ main.dart              # Point d’entrée de l’application
├─ app.dart               # Configuration globale (Store Redux, routes)
├─ models/                # Définition des modèles (User, Post, Message, etc.)
│    ├─ user.dart
│    ├─ post.dart
│    └─ message.dart
├─ redux/                 # Tout ce qui concerne Redux
│    ├─ store.dart        # Création du store Redux
│    ├─ reducers/         # Réducteurs (reducers)
│    │    ├─ user_reducer.dart
│    │    ├─ post_reducer.dart
│    │    └─ chat_reducer.dart
│    ├─ actions/          # Actions Redux
│    │    ├─ user_actions.dart
│    │    ├─ post_actions.dart
│    │    └─ chat_actions.dart
│    └─ middleware/       # Middleware (ex : logging, WebSocket)
├─ services/              # Connexion API + WebSocket
│    ├─ api_service.dart
│    └─ websocket_service.dart
├─ screens/               # Pages / écrans
│    ├─ login_screen.dart
│    ├─ signup_screen.dart
│    ├─ home_screen.dart
│    ├─ chat_screen.dart
│    └─ profile_screen.dart
├─ widgets/               # Composants réutilisables
│    ├─ message_tile.dart
│    ├─ post_card.dart
│    └─ custom_button.dart
├─ utils/                 # Fonctions utilitaires
│    ├─ validators.dart
│    └─ constants.dart

 */

// colors[
//primaryColor = #5A2A6D;
//secondaryColor = #FFFFFF;
//]