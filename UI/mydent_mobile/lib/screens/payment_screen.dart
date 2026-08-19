import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';

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

    try {
      final intent = await provider.createIntent(widget.appointmentId);

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
        Navigator.pop(context, false);
        return;
      }
      alertBox(context, "Plaćanje nije uspjelo", e.error.localizedMessage ?? e.error.message ?? '');
      Navigator.pop(context, false);
    } on Exception catch (e) {
      if (!mounted) return;
      alertBox(context, "Greška", e.toString());
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
