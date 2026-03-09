// losivio/lib/config/api_config.dart

class ApiConfig {
  static const String baseUrl = 'http://192.168.68.55:9010/api'; // https://tondomaine.com(production)
  static const String avatarUrl = 'http://192.168.68.55:9010';
  static const String socketUrl = 'ws://192.168.68.55:9011'; // wss://tondomaine.com(production)

  //static const String baseUrl = 'https://api.tonapp.com';
  //static const String socketUrl = 'wss://api.tonapp.com';

  // Authentification
  static const login = '$baseUrl/auth/login';
  static const register = '$baseUrl/auth/register';
  // Messages
  static const getContacts = '$baseUrl/messages/contacts';
  static const getMessages = '$baseUrl/messages';
  static const sendMessages = '$baseUrl/messages';
  static const sendVoiceMessage = '$baseUrl/messages/audio';
  static const getFriendFeed = '$baseUrl/follow/feed';
  //comments
  static const getComments = '$baseUrl/comments';
  static const addComment = '$baseUrl/comments/add';

  // like
  static const toggleLike = '$baseUrl/posts/like';

  // live
  static const startLive = '$baseUrl/live/start';
  static const stopLive = '$baseUrl/live/stop';
  // posts
  static const getPosts = '$baseUrl/posts/get_all_posts';
  static const uploadPost = '$baseUrl/posts/create_post';
  static const toggleFollow = '$baseUrl/follow/toggle';
  static String registerView(int postId) => '$baseUrl/post-views/$postId';

}

/*

import '../config/api_config.dart';

    String url = avatarUrl!.startsWith('http')
    ? avatarUrl!
    : '${ApiConfig.baseUrl}${avatarUrl!.startsWith('/') ? avatarUrl : '/$avatarUrl'}';


    final url = Uri.parse(ApiConfig.login);
*/