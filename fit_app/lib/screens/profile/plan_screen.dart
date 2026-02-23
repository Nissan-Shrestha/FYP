import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = [
      const _PlanData(
        title: "Free Plan",
        cardColor: Color(0xFF16A4F2),
        tileColor: Colors.white,
        accentColor: Color(0xFF16A4F2),
        billingText: "Free Plan",
        priceText: "Free",
      ),
      const _PlanData(
        title: "Premium Plan",
        cardColor: Color(0xFFD08C8C),
        tileColor: Colors.white,
        accentColor: Color(0xFFB98D8D),
        billingText: "Billed Annually",
        priceText: "\$12/yr",
      ),
      const _PlanData(
        title: "Ultra Plan",
        cardColor: Color(0xFFBBC48E),
        tileColor: Colors.white,
        accentColor: Color(0xFFC7CCA0),
        billingText: "Billed Annually",
        priceText: "25\$/yr",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF2F2F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 54,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Subscription",
          style: GoogleFonts.caveat(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        itemCount: plans.length,
        itemBuilder: (context, index) {
          final plan = plans[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == plans.length - 1 ? 0 : 28),
            child: _PlanSection(plan: plan),
          );
        },
      ),
    );
  }
}

class _PlanSection extends StatelessWidget {
  final _PlanData plan;

  const _PlanSection({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            plan.title,
            style: GoogleFonts.caveat(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                        color: plan.cardColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (plan.priceText == "Free")
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Current Plan",
                              style: GoogleFonts.caveat(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              plan.billingText,
                              style: GoogleFonts.caveat(
                                fontSize: 17,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          plan.billingText,
                          style: GoogleFonts.caveat(
                            fontSize: 17,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (plan.priceText == "Free")
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6FE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB9E2FA)),
                        ),
                        child: Text(
                          "Recommended",
                          style: GoogleFonts.caveat(
                            fontSize: 12,
                            color: plan.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                    Text(
                      plan.priceText,
                      style: GoogleFonts.caveat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: plan.cardColor.withValues(alpha: 0.45)),
                    backgroundColor: plan.cardColor.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "See Details",
                    style: GoogleFonts.caveat(
                      fontSize: 17,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanData {
  final String title;
  final Color cardColor;
  final Color tileColor;
  final Color accentColor;
  final String billingText;
  final String priceText;

  const _PlanData({
    required this.title,
    required this.cardColor,
    required this.tileColor,
    required this.accentColor,
    required this.billingText,
    required this.priceText,
  });
}

