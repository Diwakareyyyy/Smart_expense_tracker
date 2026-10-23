import 'package:flutter/material.dart';

class UpiBrandLogoWidget extends StatelessWidget {
  final String appName;
  final double size;

  const UpiBrandLogoWidget({
    super.key,
    required this.appName,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final nameLower = appName.toLowerCase();

    if (nameLower.contains("google") || nameLower.contains("gpay")) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Center(
          child: SizedBox(
            width: size * 0.8,
            height: size * 0.8,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 20, height: 1.0)),
                  Text('P', style: TextStyle(color: Color(0xFFEA4335), fontWeight: FontWeight.w800, fontSize: 18, height: 1.0)),
                  Text('a', style: TextStyle(color: Color(0xFFFBBC05), fontWeight: FontWeight.w800, fontSize: 18, height: 1.0)),
                  Text('y', style: TextStyle(color: Color(0xFF34A853), fontWeight: FontWeight.w800, fontSize: 18, height: 1.0)),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (nameLower.contains("phonepe")) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF5F259F), // PhonePe Purple
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            "पे",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
      );
    } else if (nameLower.contains("paytm")) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF002E6E),
          borderRadius: BorderRadius.circular(size / 3),
        ),
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              children: [
                TextSpan(text: 'Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                TextSpan(text: 'tm', style: TextStyle(color: Color(0xFF00BAF2), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    } else if (nameLower.contains("amazon")) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color(0xFF141920), // Amazon Dark
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: const [
            Text(
              "a",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontStyle: FontStyle.italic,
              ),
            ),
            Positioned(
              bottom: 8,
              child: Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFFF9900)),
            )
          ],
        ),
      );
    } else if (nameLower.contains("supermoney")) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00E676), Color(0xFF00C853)],
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            "⚡S",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      );
    } else if (nameLower.contains("bhim")) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00529B), Color(0xFFF37023)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text(
            "BHIM",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      );
    } else if (nameLower.contains("cred")) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: const Center(
          child: Text(
            "CRED",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    }

    // Default Fallback
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xff7B4DFF),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
      ),
    );
  }
}
