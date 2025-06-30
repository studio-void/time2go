import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;

class TestFrame extends StatefulWidget {
  const TestFrame({super.key});

  @override
  State<TestFrame> createState() => _TestFrameState();
}

class _TestFrameState extends State<TestFrame> {
  final _googleSignIn = GoogleSignIn(
    scopes: <String>[calendar.CalendarApi.calendarScope],
    serverClientId: dotenv.env['GOOGLE_CLIENT_ID']!,
  );

  // GoogleSignInAccount? _currentUser;
  late var httpClient;

  void _handleSignIn() async {
    _googleSignIn
        .signIn()
        .then((GoogleSignInAccount? account) {
          if (account == null) {
            // User cancelled the sign-in
            return;
          }
          print("Trying to get Google account...");
          _getGoogleAccount()
              .then((_) {
                // Successfully signed in and authenticated
                print('Signed in as: ${account.displayName}');
                print(
                  'Access Token: ${httpClient.credentials.accessToken.data}',
                );
              })
              .catchError((error) {
                print('Error getting Google account: $error');
              });
        })
        .catchError((error) {
          print('Sign-in failed: $error');
        });
  }

  Future<void> _getGoogleAccount() async {
    httpClient = (await _googleSignIn.authenticatedClient())!;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: InkWell(
                onTap: _handleSignIn,
                child: Row(
                  children: [
                    Icon(Icons.account_box),
                    const SizedBox(width: 8),
                    Text('Get Google Account'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
