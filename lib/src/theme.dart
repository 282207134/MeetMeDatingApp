import 'dart:io';
import 'package:flutter/material.dart';
import 'store.dart';

const blue = Color(0xFF0865DE);
const cyan = Color(0xFF64DBE8);
const ink = Color(0xFF172D44);
const canvas = Color(0xFFF5FAFE);
const brandGradient = LinearGradient(
  colors: [cyan, Color(0xFF36A3E6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: blue,
    primary: blue,
    secondary: cyan,
    surface: Colors.white,
    onSurface: ink,
  ),
  textTheme: ThemeData.light().textTheme.apply(
    bodyColor: ink,
    displayColor: ink,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    centerTitle: true,
    elevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: blue.withValues(alpha: .12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: blue.withValues(alpha: .12)),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: BorderSide(color: blue.withValues(alpha: .2)),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: cyan.withValues(alpha: .2),
    labelTextStyle: WidgetStateProperty.all(
      const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  ),
);

class BrandHeader extends StatelessWidget {
  const BrandHeader(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: brandGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    padding: EdgeInsets.fromLTRB(
      24,
      MediaQuery.paddingOf(context).top + 14,
      24,
      24,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        Image.asset('assets/images/logo.png', width: 52, height: 56),
      ],
    ),
  );
}

class Avatar extends StatelessWidget {
  const Avatar({this.person, this.profile, this.size = 56, super.key});
  final Person? person;
  final Profile? profile;
  final double size;
  @override
  Widget build(BuildContext context) {
    final path = profile?.photoPath;
    final ImageProvider image = path != null && File(path).existsSync()
        ? FileImage(File(path))
        : AssetImage('assets/images/${person?.image ?? 'avatar_me'}.png');
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        image: DecorationImage(image: image, fit: BoxFit.cover),
      ),
    );
  }
}

class InterestChips extends StatelessWidget {
  const InterestChips(this.items, {super.key, this.selected, this.onTap});
  final List<String> items;
  final List<String>? selected;
  final ValueChanged<String>? onTap;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: items.map((item) {
      final active = selected == null || selected!.contains(item);
      return Material(
        color: active ? cyan.withValues(alpha: .2) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap == null ? null : () => onTap!(item),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(
                color: active ? cyan : const Color(0xFFDCE7F0),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              item,
              style: TextStyle(
                color: active ? blue : ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class EmptyCard extends StatelessWidget {
  const EmptyCard(
    this.icon,
    this.title,
    this.message, {
    this.action,
    super.key,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cyan.withValues(alpha: .15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: blue),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blueGrey, height: 1.5),
          ),
          if (action != null) ...[const SizedBox(height: 22), action!],
        ],
      ),
    ),
  );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE8F0F6)),
    ),
    child: child,
  );
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(90, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

void openPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
