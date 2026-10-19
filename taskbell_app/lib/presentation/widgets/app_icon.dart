import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taskbell_app/core/theme/app_theme.dart';

/// Path aset ikon SVG (set Lucide, lisensi ISC).
class AppIcons {
  static const String home = 'assets/icons/svg/home.svg';
  static const String tasks = 'assets/icons/svg/clipboard-list.svg';
  static const String calendarDays = 'assets/icons/svg/calendar-days.svg';
  static const String calendar = 'assets/icons/svg/calendar.svg';
  static const String clock = 'assets/icons/svg/clock.svg';
  static const String send = 'assets/icons/svg/send.svg';
  static const String plus = 'assets/icons/svg/plus.svg';
  static const String pencil = 'assets/icons/svg/pencil.svg';
  static const String trash = 'assets/icons/svg/trash-2.svg';
  static const String check = 'assets/icons/svg/check.svg';
  static const String search = 'assets/icons/svg/search.svg';
  static const String cloud = 'assets/icons/svg/cloud.svg';
  static const String refresh = 'assets/icons/svg/refresh-cw.svg';
  static const String cloudCheck = 'assets/icons/svg/cloud-check.svg';
  static const String cloudOff = 'assets/icons/svg/cloud-off.svg';
  static const String lock = 'assets/icons/svg/lock.svg';
  static const String user = 'assets/icons/svg/circle-user-round.svg';
  static const String chevronLeft = 'assets/icons/svg/chevron-left.svg';
  static const String chevronRight = 'assets/icons/svg/chevron-right.svg';
  static const String flag = 'assets/icons/svg/flag.svg';
  static const String settings = 'assets/icons/svg/settings-2.svg';
  static const String eye = 'assets/icons/svg/eye.svg';
  static const String eyeOff = 'assets/icons/svg/eye-off.svg';
  static const String moreVertical = 'assets/icons/svg/ellipsis-vertical.svg';
  static const String circleCheck = 'assets/icons/svg/circle-check.svg';
}

/// Menampilkan ikon SVG dengan warna tema.
///
/// Tanpa [semanticLabel], ikon dianggap dekoratif dan disembunyikan dari
/// pembaca layar.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String asset;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    final picture = SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? palette.ink,
        BlendMode.srcIn,
      ),
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: picture);
    }

    return Semantics(
      label: semanticLabel,
      image: true,
      child: picture,
    );
  }
}
