import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

import '../models/payment_intent.dart' as mydent;
import '../providers/payment_provider.dart';
import '../utils/utils_widgets.dart';

class PaymentScreen extends StatefulWidget {
  final int appointmentId;

  const PaymentScreen({super.key, required this.appointmentId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPayment());
  }

  Future<void> _startPayment() async {
    setState(() => _isProcessing = true);
    final provider = context.read<PaymentProvider>();
    mydent.PaymentIntent? intent;

    // Without a publishable key, Stripe.instance.initPaymentSheet() below doesn't throw — it
    // just hangs forever with no error, which is exactly the "keeps spinning until I force-quit"
    // symptom this used to cause. Fail loudly and immediately instead.
    if (Stripe.publishableKey.isEmpty) {
      setState(() => _isProcessing = false);
      await alertBox(context, "Plaćanje nije dostupno",
          "Stripe nije konfigurisan (nedostaje publishable key). Kontaktirajte administratora aplikacije.");
      if (!mounted) return;
      Navigator.pop(context, false);
      return;
    }

    try {
      intent = await provider.createIntent(widget.appointmentId);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          customerEphemeralKeySecret: intent.ephemeralKey,
          customerId: intent.customerId,
          merchantDisplayName: "MyDent",
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Belt-and-suspenders: the Stripe webhook is the source of truth, but calling Confirm
      // here eagerly reflects the paid status without waiting on the webhook round-trip.
      await provider.confirm(intent.paymentId!);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on StripeException catch (e) {
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        // Without this, the Pending Payment row CreateIntentAsync already created stays Pending
        // forever — looking like an unresolved payment in the Payments list and blocking any
        // retry (PaymentCreateIntentValidator refuses a new intent while one still exists).
        try {
          if (intent?.paymentId != null) await provider.cancel(intent!.paymentId!);
        } catch (_) {
          // Best-effort — the patient can still retry later; nothing to block the pop on here.
        }
        if (!mounted) return;
        Navigator.pop(context, false);
        return;
      }
      // Must be awaited — popping this screen right after showing the dialog
      // (without waiting for it to actually be dismissed) tears the dialog
      // down before the patient ever gets to read why the payment failed.
      await alertBox(context, "Plaćanje nije uspjelo",
          e.error.localizedMessage ?? e.error.message ?? '');
      if (!mounted) return;
      Navigator.pop(context, false);
    } on Exception catch (e) {
      if (!mounted) return;
      await alertBox(context, "Greška", e.toString());
      if (!mounted) return;
      Navigator.pop(context, false);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Plaćanje")),
      body: Center(
        child: _isProcessing
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Priprema plaćanja..."),
                ],
              )
            : const Text("Zatvaranje..."),
      ),
    );
  }
}
