import 'package:flutter/material.dart';
import 'package:happy_oven/core/theme/theme.dart';

/// Piezas de UI compartidas que replican el prototipo de diseño de Happy Oven
/// (encabezados con degradado, tarjetas, etiquetas de sección, campos, badges).

/// Encabezado de pantalla principal: degradado khaki, título serif, subtítulo,
/// acción opcional a la derecha y contenido extra debajo (buscador, pestañas).
class HoHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget? bottom;
  final Widget? leading;
  final bool gradient;

  const HoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.bottom,
    this.leading,
    this.gradient = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: gradient ? null : c.bg,
        gradient: gradient
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.khaki, c.khakiSoft],
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.serif(
                            TextStyle(
                              fontSize: 26,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              color: c.titleText,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.bodyText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (action != null) ...[const SizedBox(width: 8), action!],
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 12), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra superior de subpantalla con botón de retroceso cuadrado.
class HoTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottom;

  const HoTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(bottom != null ? 124 : 76);

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c.khaki, c.khakiSoft],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  HoIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 19,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                            color: c.titleText,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.bodyText),
                          ),
                      ],
                    ),
                  ),
                  ...actions,
                ],
              ),
              if (bottom != null) ...[const SizedBox(height: 10), bottom!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón cuadrado redondeado (retroceso, acciones de barra).
class HoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool round;
  final Color? background;
  final Color? foreground;
  final String? tooltip;

  const HoIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.round = false,
    this.background,
    this.foreground,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final radius = BorderRadius.circular(round ? 999 : 12);
    final button = Material(
      color: background ?? c.card,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: background == null ? Border.all(color: c.border) : null,
          ),
          child: Icon(icon, size: 20, color: foreground ?? c.titleText),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Botón compacto del encabezado ("+ Nuevo", "Exportar").
class HoHeaderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const HoHeaderButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: c.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta blanca con borde fino y sombra suave.
class HoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final Color? borderColor;

  const HoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 20,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final br = BorderRadius.circular(radius);
    return Container(
      decoration: BoxDecoration(
        color: color ?? c.card,
        borderRadius: br,
        border: Border.all(color: borderColor ?? c.border),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: br,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Etiqueta de sección en mayúsculas.
class HoSectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const HoSectionLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text.toUpperCase(),
      style: AppTheme.fontOf(context).section,
    );
    if (trailing == null) return label;
    return Row(
      children: [
        Expanded(child: label),
        trailing!,
      ],
    );
  }
}

/// Badge tipo píldora.
class HoBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;

  const HoBadge({
    super.key,
    required this.text,
    required this.color,
    required this.background,
  });

  /// Badge de estado de stock: Normal (verde) / Bajo / Crítico.
  factory HoBadge.estado(BuildContext context, {required bool bajo, bool critico = false}) {
    final c = AppTheme.colorsOf(context);
    if (critico) {
      return HoBadge(text: 'Crítico', color: c.statusCritical, background: c.dangerLight);
    }
    if (bajo) {
      return HoBadge(text: 'Bajo', color: c.primaryDark, background: c.primaryLight);
    }
    return HoBadge(text: 'Normal', color: c.successDeep, background: c.successLight);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Barra de progreso fina redondeada.
class HoProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color? background;

  const HoProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 6,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: background ?? c.border,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

/// Botón principal de ancho completo.
class HoPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final bool pill;

  const HoPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.color,
    this.pill = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final enabled = onPressed != null && !loading;
    final br = BorderRadius.circular(pill ? 999 : 16);
    return Material(
      color: enabled ? (color ?? c.primary) : c.hint,
      borderRadius: br,
      elevation: enabled ? 2 : 0,
      shadowColor: (color ?? c.primary).withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: br,
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: c.white),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: c.white,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Campo de búsqueda blanco con icono de lupa.
class HoSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const HoSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: c.titleText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: c.hint),
          prefixIcon: Icon(Icons.search_rounded, color: c.bodyText, size: 20),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

/// Decoración de campo de formulario del diseño (fondo azulado, radio 16).
InputDecoration hoInputDecoration(
  BuildContext context, {
  String? hint,
  IconData? icon,
  String? suffixText,
  Widget? suffixIcon,
  String? prefixText,
}) {
  final c = AppTheme.colorsOf(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: c.border),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 15, color: c.hint),
    prefixIcon: icon != null ? Icon(icon, size: 20, color: c.bodyText) : null,
    prefixText: prefixText,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: c.primaryLight.withValues(alpha: 0.6),
    border: border,
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: c.primary, width: 2),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: c.statusCritical),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
  );
}

/// Campo con etiqueta en mayúsculas encima.
class HoLabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const HoLabeledField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: AppTheme.fontOf(context).section),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Tarjeta de costo verde (Resumen de costos).
class HoCostCard extends StatelessWidget {
  final String label;
  final String value;

  const HoCostCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.successLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: c.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.successDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pestañas subrayadas (Todas / Mis recetas / …).
class HoUnderlineTabs extends StatelessWidget {
  final List<String> labels;
  final List<IconData>? icons;
  final int selected;
  final ValueChanged<int> onChanged;

  const HoUnderlineTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.icons,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8, top: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: selected == i ? c.primary : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (icons != null) ...[
                        Icon(
                          icons![i],
                          size: 16,
                          color: selected == i ? c.titleText : c.bodyText,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected == i ? c.titleText : c.bodyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Logo circular navy con espiga y marca "HAPPY OVEN".
class HoLogo extends StatelessWidget {
  final double size;

  const HoLogo({super.key, this.size = 124});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(0, -0.3),
          radius: 0.9,
          colors: [Color(0xFF0B2137), Color(0xFF1A385C)],
        ),
        border: Border.all(
          color: const Color(0xFF0B2137).withValues(alpha: 0.2),
          width: 4,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B2137).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bakery_dining_rounded, color: Colors.white, size: size * 0.32),
          SizedBox(height: size * 0.03),
          Text(
            'HAPPY OVEN',
            style: TextStyle(
              fontSize: size * 0.1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: size * 0.02),
          Text(
            'ARTESANAL',
            style: TextStyle(
              fontSize: size * 0.058,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interruptor verde del diseño.
class HoSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const HoSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: c.white,
      activeTrackColor: c.statusNormal,
      inactiveThumbColor: c.white,
      inactiveTrackColor: c.border,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// Foto de red con respaldo (icono) si no carga o no hay ID.
class HoPhoto extends StatelessWidget {
  final String? photoId;
  final double? width;
  final double? height;
  final int px;
  final BorderRadius? radius;
  final IconData fallbackIcon;

  const HoPhoto({
    super.key,
    required this.photoId,
    this.width,
    this.height,
    this.px = 200,
    this.radius,
    this.fallbackIcon = Icons.bakery_dining_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final fallback = Container(
      width: width,
      height: height,
      color: c.primaryLight,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, color: c.accent, size: 28),
    );
    final child = photoId == null
        ? fallback
        : Image.network(
            'https://images.unsplash.com/photo-$photoId?w=$px&h=$px&fit=crop&auto=format',
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
            loadingBuilder: (_, img, progress) =>
                progress == null ? img : Container(color: c.bg),
          );
    return ClipRRect(borderRadius: radius ?? BorderRadius.zero, child: child);
  }
}
