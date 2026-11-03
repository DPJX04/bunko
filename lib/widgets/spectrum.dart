import 'package:flutter/material.dart';

/// The emission lines: the only colours the app's own chrome uses, each tied
/// to one meaning, and the book lines that tell books apart on Library.
///
/// Dark mode shows them glowing on black. Light mode darkens them into
/// absorption lines on bone, so each still has at least 3:1 contrast.
@immutable
class Spectrum extends ThemeExtension<Spectrum> {
  const Spectrum({
    required this.violet,
    required this.cyan,
    required this.green,
    required this.sodium,
    required this.red,
    required this.books,
    required this.glow,
  });

  /// 405 nm: marks the Browse tab.
  final Color violet;

  /// 486 nm: saved volumes and the Library tab.
  final Color cyan;

  /// 546 nm: marks the Downloads tab.
  final Color green;

  /// 589 nm: downloading right now, and nothing else.
  final Color sodium;

  /// 656 nm: failed.
  final Color red;

  /// The book lines, one per book on Library, cyan first. Their only
  /// meaning is "this book", so none is sodium (downloading) or red
  /// (failed), and the warm and cool ones alternate.
  final List<Color> books;

  /// How strongly lines glow: 1 on black, 0 on bone where glow muddies.
  final double glow;

  /// The book line for a book's colour slot, starting over after the last.
  Color book(int slot) => books[slot % books.length];

  /// Lines glowing on the black plate.
  static const emission = Spectrum(
    violet: Color(0xFFA07CFF),
    cyan: Color(0xFF5BC0F0),
    green: Color(0xFF6CCB5F),
    sodium: Color(0xFFF5C542),
    red: Color(0xFFFF6B5A),
    books: [
      Color(0xFF5BC0F0), // cyan, as the Library tab
      Color(0xFFF27BC4), // rose
      Color(0xFF4FD1B0), // jade
      Color(0xFFFF9A52), // orange
      Color(0xFF8C9BFF), // periwinkle
      Color(0xFFB9DB4C), // lime
    ],
    glow: 1,
  );

  /// The same lines darkened for the bone plate.
  static const absorption = Spectrum(
    violet: Color(0xFF5B34C9),
    cyan: Color(0xFF0E6E99),
    green: Color(0xFF2E7D23),
    sodium: Color(0xFF8C6A00),
    red: Color(0xFFB3261E),
    // Each at least 3:1 on the bone plate.
    books: [
      Color(0xFF0E6E99),
      Color(0xFFA8336F),
      Color(0xFF12765F),
      Color(0xFFA3500F),
      Color(0xFF3E4BB8),
      Color(0xFF5A6B12),
    ],
    glow: 0,
  );

  /// Reads the spectrum from the current theme.
  static Spectrum of(BuildContext context) {
    return Theme.of(context).extension<Spectrum>() ?? emission;
  }

  @override
  Spectrum copyWith({
    Color? violet,
    Color? cyan,
    Color? green,
    Color? sodium,
    Color? red,
    List<Color>? books,
    double? glow,
  }) {
    return Spectrum(
      violet: violet ?? this.violet,
      cyan: cyan ?? this.cyan,
      green: green ?? this.green,
      sodium: sodium ?? this.sodium,
      red: red ?? this.red,
      books: books ?? this.books,
      glow: glow ?? this.glow,
    );
  }

  @override
  Spectrum lerp(Spectrum? other, double t) {
    if (other == null) return this;
    return Spectrum(
      violet: Color.lerp(violet, other.violet, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      green: Color.lerp(green, other.green, t)!,
      sodium: Color.lerp(sodium, other.sodium, t)!,
      red: Color.lerp(red, other.red, t)!,
      books: [
        for (final (i, line) in books.indexed)
          Color.lerp(line, other.books[i], t)!,
      ],
      glow: glow + (other.glow - glow) * t,
    );
  }
}
