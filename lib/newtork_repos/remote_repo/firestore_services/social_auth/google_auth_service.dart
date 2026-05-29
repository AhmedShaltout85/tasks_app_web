// import 'dart:developer';

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// // Google Sign-In Service Class
// class GoogleSignInService {
//   static final FirebaseAuth _auth = FirebaseAuth.instance;
//   static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
//   static bool isInitialize = false;
//   static Future<void> initSignIn() async {
//     if (!isInitialize) {
//       await _googleSignIn.initialize(
//         serverClientId:
//             // '484988555302-d91nev5jn5sit0qoe3oehpgpp58pl5mt.apps.googleusercontent.com',
//             '513006185811-umqfk692e0enhtv52kjh1v1eskih8p1k.apps.googleusercontent.com',
//       );
//     }
//     isInitialize = true;
//   }

//   // Sign in with Google
//   static Future<UserCredential?> signInWithGoogle() async {
//     try {
//       initSignIn();
//       final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
//       final idToken = googleUser.authentication.idToken;
//       final authorizationClient = googleUser.authorizationClient;
//       GoogleSignInClientAuthorization? authorization = await authorizationClient
//           .authorizationForScopes(['email', 'profile']);
//       final accessToken = authorization?.accessToken;
//       if (accessToken == null) {
//         final authorization2 = await authorizationClient.authorizationForScopes(
//           ['email', 'profile'],
//         );
//         if (authorization2?.accessToken == null) {
//           throw FirebaseAuthException(code: "error", message: "error");
//         }
//         authorization = authorization2;
//       }
//       final credential = GoogleAuthProvider.credential(
//         accessToken: accessToken,
//         idToken: idToken,
//       );
//       final UserCredential userCredential = await FirebaseAuth.instance
//           .signInWithCredential(credential);
//       // Save user data to Firestore
//       // await AddNewUserToDB.saveUserInfo(userCredential);
//       return userCredential;
//     } catch (e) {
//       log('Error: $e');
//       rethrow;
//     }
//   }

//   // Sign out
//   static Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//       await _auth.signOut();
//     } catch (e) {
//       log('Error signing out: $e');
//       throw e.toString();
//     }
//   }

//   // Get current user
//   static User? getCurrentUser() {
//     return _auth.currentUser;
//   }
// }

// // https://codewtf.com/google-sign-in-flutter-firebase/
