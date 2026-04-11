import 'package:fit_app/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewmodel>();
    final currentPlan = (authVM.profile?.plan ?? 'free').toLowerCase();

    final plans = [
      _PlanData(
        id: 'free',
        title: "Free",
        cardColor: const Color(0xFF16A4F2),
        price: "\$0",
        period: "Forever",
        features: [
          "Max 25 Clothing Items",
          "Max 5 Wardrobes",
          "1 AI Suggestion / Day",
          "Community Access",
        ],
        isCurrent: currentPlan == 'free',
      ),
      _PlanData(
        id: 'premium',
        title: "Premium",
        cardColor: const Color(0xFF673AB7),
        price: "\$4.99",
        period: "/ month",
        features: [
          "Unlimited Clothing Items",
          "Unlimited Wardrobes",
          "Unlimited AI Styling",
          "Community Access",
        ],
        isCurrent: currentPlan == 'premium',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.black,
          ),
        ),
        title: Text(
          "Subscription",
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Text(
              currentPlan == 'premium' ? "You're Premium!" : "Simple Pricing",
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentPlan == 'premium'
                  ? "Enjoy unlimited AI styling and wardrobe audits."
                  : "Choose the plan that fits your closet",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ...plans.map((plan) => _PlanCard(plan: plan, currentPlan: currentPlan)),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanData plan;
  final String currentPlan;
  const _PlanCard({required this.plan, required this.currentPlan});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: plan.isCurrent
            ? Border.all(color: plan.cardColor, width: 2)
            : Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (plan.isCurrent)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: plan.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
              ),
              child: Text(
                "ACTIVE",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price,
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 2),
                          child: Text(
                            plan.period,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),
                ...plan.features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          feature.contains("Max")
                              ? Icons.info_outline_rounded
                              : Icons.check_circle_rounded,
                          size: 18,
                          color: plan.cardColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (!(currentPlan == 'premium' && plan.id == 'free'))
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: plan.isCurrent
                          ? null
                          : () {
                              // Logic to start Stripe checkout
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: plan.id == 'premium'
                            ? plan.cardColor
                            : Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade100,
                        disabledForegroundColor: Colors.grey.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        plan.isCurrent
                            ? "Active Plan"
                            : (plan.id == 'premium'
                                ? "Upgrade to Premium"
                                : "Switch to Free"),
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanData {
  final String id;
  final String title;
  final Color cardColor;
  final String price;
  final String period;
  final List<String> features;
  final bool isCurrent;

  const _PlanData({
    required this.id,
    required this.title,
    required this.cardColor,
    required this.price,
    required this.period,
    required this.features,
    required this.isCurrent,
  });
}
