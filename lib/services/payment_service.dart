import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';

class PaymentService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    Stripe.publishableKey = PaymentConfig.publishableKey;
    Stripe.instance.applySettings();
    _initialized = true;
  }

  // Create PaymentIntent via your backend and return its clientSecret
  static Future<String> _createPaymentIntent({
    required int amountInMinorUnit,
    required String currency,
    required String username,
    String? description,
  }) async {
    final url = Uri.parse(
      '${PaymentConfig.backendBaseUrl}/create-payment-intent',
    );

    print('📤 Sending request to: $url');
    print('⚡ Creating PaymentIntent for $username...');

    // Send request with Supabase anon key as apikey header
    // This tells Supabase it's an authenticated public request
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9heGxqaXR5anpqeWx2dm1mcnRhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNjc3MjAsImV4cCI6MjA3NzY0MzcyMH0.DFdoQ7nIgxVzRXgjjecsEBEcED4z2zngtq6XWEtTegM',
      },
      body: jsonEncode({
        'amount': amountInMinorUnit,
        'currency': currency,
        'metadata': {
          'username': username,
          if (description != null) 'description': description,
        },
      }),
    );

    print('📨 Response status: ${response.statusCode}');
    print('📨 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create PaymentIntent (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['client_secret'] as String?;
    if (clientSecret == null || clientSecret.isEmpty) {
      throw Exception('Missing client_secret from backend');
    }
    return clientSecret;
  }

  // Initialize and present the PaymentSheet; returns true on successful payment
  static Future<bool> payWithPaymentSheet({
    required double amount,
    required String currency,
    required String username,
    String? description,
    // Optional billing details to prefill Stripe sheet (non-sensitive)
    BillingDetails? billingDetails,
  }) async {
    // On web, Stripe PaymentSheet is not supported, so we simulate payment
    // For production web, you'd integrate Stripe Elements or redirect to Stripe Checkout
    if (kIsWeb) {
      print(
        '⚠️  Web platform detected - simulating payment (PaymentSheet not supported on web)',
      );
      print('💰 Simulated payment: RM${amount.toStringAsFixed(2)}');
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      print('✅ Simulated payment completed successfully');
      return true; // Return success for web testing
    }

    try {
      // For mobile: Try PaymentSheet first, but fall back to simulated payment if it fails
      print('📱 Mobile platform detected');

      await init();

      // Stripe expects amounts in the smallest currency unit (e.g., cents)
      final amountInMinorUnit = (amount * 100).round();

      // 1) Create PaymentIntent on backend
      print('⏳ Creating PaymentIntent...');
      final clientSecret =
          await _createPaymentIntent(
            amountInMinorUnit: amountInMinorUnit,
            currency: currency,
            username: username,
            description: description,
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('PaymentIntent creation timeout'),
          );

      print('✅ PaymentIntent created: $clientSecret');
      print('🎫 Initializing PaymentSheet...');

      // 2) Init PaymentSheet with error handling
      try {
        print('� Initializing PaymentSheet (memory-optimized)...');
        await Stripe.instance
            .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                paymentIntentClientSecret: clientSecret,
                merchantDisplayName: 'UniPerks',
                style: ThemeMode.light,
                // Disable features that consume memory
                allowsDelayedPaymentMethods: false,
                // Prefill allowed fields (name/address)
                billingDetails: billingDetails,
              ),
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () =>
                  throw Exception('PaymentSheet initialization timeout'),
            );
      } on StripeException catch (e) {
        print('❌ Stripe Exception during init: ${e.error.localizedMessage}');
        throw Exception(
          'PaymentSheet init failed: ${e.error.localizedMessage}',
        );
      } catch (e) {
        print('❌ Exception during PaymentSheet init: $e');
        throw Exception('PaymentSheet init error: $e');
      }

      print('✅ PaymentSheet initialized successfully');
      print('� Presenting PaymentSheet to user...');

      // 3) Present PaymentSheet with error handling
      try {
        await Stripe.instance.presentPaymentSheet().timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('Payment presentation timeout'),
        );
        print('✅ Payment completed successfully');
        return true;
      } on StripeException catch (e) {
        // Check if user cancelled (not an actual error)
        if (e.error.code.toString().contains('Cancelled')) {
          print('⚠️  Payment cancelled by user');
          return false;
        }
        print('❌ Stripe Exception during payment: ${e.error.localizedMessage}');
        // Treat as failure; do not proceed
        return false;
      }
    } catch (e) {
      print('❌ Payment error: $e');
      // Do not simulate success; keep user on payment step
      return false;
    }
  }
}
