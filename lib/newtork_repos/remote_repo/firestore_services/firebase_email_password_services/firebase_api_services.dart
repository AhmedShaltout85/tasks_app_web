import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class FirebaseApiSAuthServices {
  static FirebaseApiSAuthServices instance = FirebaseApiSAuthServices();

  static Future<void> createUserWithEmailAndPassword({
    required String emailAddress,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailAddress,
            password: password,
          );
      //save user data
      // await AddNewUserToDB.saveUserInfo(credential);

      //
      log(credential.user!.email.toString());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        log('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        log('The account already exists for that email.');
      }
    } catch (e) {
      log(e.toString());
    }
  }

  //sign in
  static Future<void> signInWithEmailAndPassword({
    required String emailAddress,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailAddress,
        password: password,
      );
      log(credential.user!.email.toString());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        log('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        log('Wrong password provided for that user.');
      }
    }
  }

  //sign out

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  //reset password

  static Future<void> resetPassword({required String emailAddress}) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: emailAddress);
  }

  //send verification email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      // Show success message to user
    } on FirebaseAuthException catch (e) {
      // Handle specific errors
      log('Firebase Auth Error: ${e.code} - ${e.message}');
      // Show a user-friendly message based on e.code
      if (e.code == 'invalid-email') {
        // Handle invalid email
      } else if (e.code == 'user-not-found') {
        // It's often safer to show a generic success message even for this case
      }
      // Add other error codes as needed
    } catch (e) {
      // Handle any other unexpected errors
      log('General Error: $e');
    }
  }

  //verify email

  static Future<void> verifyEmail() async {
    await FirebaseAuth.instance.currentUser?.sendEmailVerification();
  }
  // static Future<void> verifyEmail() async {
  //   try {
  //     final user = FirebaseAuth.instance.currentUser;

  //     if (user == null) {
  //       throw Exception('No user is currently signed in');
  //     }

  //     if (!user.emailVerified) {
  //       await user.sendEmailVerification();
  //       log('Verification email sent to ${user.email}');
  //     } else {
  //       log('Email is already verified');
  //     }
  //   } catch (e) {
  //     log('Error sending verification email: $e');
  //     rethrow;
  //   }
  // }

  //update password

  static Future<void> updatePassword({required String newPassword}) async {
    await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
  }
}
