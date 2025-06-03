import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No user found for that email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Wrong password provided.';
            break;
          default:
            _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            _errorMessage =
            'This email is already associated with a different sign-in method.';
            break;
          case 'invalid-credential':
            _errorMessage = 'Google credential is invalid or expired.';
            break;
          default:
            _errorMessage = e.message;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during Google Sign-In.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mastermind')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background4.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Linear progress bar above input
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),

                const SizedBox(height: 30),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white38),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

                const SizedBox(height: 12),

                // Log In button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Log In',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Sign Up link
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (c) => const SignupScreen()),
                    );
                  },
                  child: const Text(
                    "Don't have an account? Sign up",
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign in with Google
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  icon: Image.asset(
                    'assets/images/google_logo.png',
                    height: 24,
                    width: 24,
                  ),
                  label: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16),
                  ),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
