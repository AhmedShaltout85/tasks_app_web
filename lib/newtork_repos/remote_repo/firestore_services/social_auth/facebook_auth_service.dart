// import 'dart:developer';

// import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// class FacebookAuthService {
//   static final FacebookAuth _facebookAuth = FacebookAuth.instance;

//   /// Login with Facebook
//   /// Returns user data if successful, null otherwise
//   static Future<Map<String, dynamic>?> login() async {
//     try {
//       final LoginResult result = await _facebookAuth.login(
//         permissions: ['email', 'public_profile'],
//       );

//       if (result.status == LoginStatus.success) {
//         // Access token is available in result.accessToken
//         final AccessToken? accessToken = result.accessToken;

//         if (accessToken != null) {
//           // Get user data
//           final userData = await _facebookAuth.getUserData(
//             fields: "name,email,picture.width(200)",
//           );
//           return userData;
//         }
//       } else if (result.status == LoginStatus.cancelled) {
//         log('Facebook login cancelled by user');
//       } else if (result.status == LoginStatus.failed) {
//         log('Facebook login failed: ${result.message}');
//       }

//       return null;
//     } catch (e) {
//       log('Facebook login error: $e');
//       return null;
//     }
//   }

//   /// Check if user is currently logged in
//   static Future<bool> isLoggedIn() async {
//     try {
//       final AccessToken? token = await _facebookAuth.accessToken;
//       return token != null && !token.tokenString.isNotEmpty;
//     } catch (e) {
//       log('Error checking login status: $e');
//       return false;
//     }
//   }

//   /// Logout from Facebook
//   static Future<void> logout() async {
//     try {
//       await _facebookAuth.logOut();
//     } catch (e) {
//       log('Facebook logout error: $e');
//     }
//   }

//   /// Get current access token
//   static Future<AccessToken?> getAccessToken() async {
//     try {
//       return await _facebookAuth.accessToken;
//     } catch (e) {
//       log('Error getting access token: $e');
//       return null;
//     }
//   }

//   /// Get current user data (if logged in)
//   static Future<Map<String, dynamic>?> getUserData() async {
//     try {
//       final bool loggedIn = await isLoggedIn();
//       if (loggedIn) {
//         return await _facebookAuth.getUserData(
//           fields: "name,email,picture.width(200)",
//         );
//       }
//       return null;
//     } catch (e) {
//       log('Error getting user data: $e');
//       return null;
//     }
//   }
// }
