import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CategoryVisual {
  const CategoryVisual({required this.icon, required this.emoji, this.color});

  final IconData icon;
  final String emoji;
  final Color? color;
}

final Map<String, CategoryVisual> categoryVisuals = <String, CategoryVisual>{
  'Food': CategoryVisual(
    icon: FontAwesomeIcons.bowlFood,
    emoji: '🍔',
    color: const Color(0xFFFF7043),
  ),
  'Travel': CategoryVisual(
    icon: FontAwesomeIcons.planeDeparture,
    emoji: '✈️',
    color: const Color(0xFF29B6F6),
  ),
  'Bills': CategoryVisual(
    icon: FontAwesomeIcons.fileInvoiceDollar,
    emoji: '💡',
    color: const Color(0xFFFFCA28),
  ),
  'Shopping': CategoryVisual(
    icon: FontAwesomeIcons.bagShopping,
    emoji: '🛍️',
    color: const Color(0xFFAB47BC),
  ),
  'Entertainment': CategoryVisual(
    icon: FontAwesomeIcons.film,
    emoji: '🎬',
    color: const Color(0xFFEC407A),
  ),
  'Health': CategoryVisual(
    icon: FontAwesomeIcons.heartPulse,
    emoji: '💖',
    color: const Color(0xFF66BB6A),
  ),
  'Work': CategoryVisual(
    icon: FontAwesomeIcons.briefcase,
    emoji: '💼',
    color: const Color(0xFF42A5F5),
  ),
  'Other': CategoryVisual(
    icon: FontAwesomeIcons.ellipsis,
    emoji: '🧩',
    color: const Color(0xFF9E9E9E),
  ),
};
