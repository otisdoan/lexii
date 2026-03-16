import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Run me with: flutter run -t test_real.dart -d macos

void main() async {
  print('Starting test...');
  
  await Supabase.initialize(
    url: 'https://bkkpaaacxftqlidaxnml.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJra3BhYWFjeGZ0cWxpZGF4bm1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxODQzMzQsImV4cCI6MjA4Nzc2MDMzNH0.NJ23R9N-1cn3OtpZgacoy28K_bbNZUXkE9AZ31I2HqI',
  );

  final client = Supabase.instance.client;

  print('Please enter your email:');
  final email = stdin.readLineSync() ?? '';
  print('Please enter your password:');
  final password = stdin.readLineSync() ?? '';

  try {
    final authRes = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    print('Logged in as: \${authRes.user?.id}');
    
    final session = client.auth.currentSession;
    if (session == null) {
      print('Error: No session found after login');
      exit(1);
    }
    
    print('Token snippet: \${session.accessToken.substring(0, 20)}...');

    print('Calling create-payos-payment function...');
    final response = await client.functions.invoke(
      'create-payos-payment',
      body: {
        'planId': 'premium_6_months',
        'planName': 'Premium 6 thang',
        'amount': 299000,
        'description': 'Lexii Premium test',
      },
    );

    print('Response status: \${response.status}');
    print('Response data: \${response.data}');
  } on AuthException catch (e) {
    print('Auth Error: \${e.message}');
  } on FunctionException catch (e) {
    print('Function Error (\${e.status}): \${e.reasonPhrase}');
    print('Details: \${e.details}');
  } catch (e) {
    print('Generic Error: \$e');
  }
  
  exit(0);
}
