import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
    this.headerBottomWidget,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;
  final Widget? headerBottomWidget;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 28,
        vertical: 20,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null && width > 680) trailing!,
          ],
        ),
        if (trailing != null && width <= 680) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerLeft, child: trailing!),
        ],
        if (headerBottomWidget != null) ...[
          const SizedBox(height: 16),
          headerBottomWidget!,
        ],
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

/// Etiqueta de estado (Activo / Inactivo).
class AdminStatusTag extends StatelessWidget {
  const AdminStatusTag(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final active = label.toLowerCase() == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.successText : AppColors.warningText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Campo de texto de formulario estandarizado con separación inferior.
class AdminFormField extends StatelessWidget {
  const AdminFormField({
    super.key,
    required this.controller,
    required this.label,
    this.enabled = true,
    this.keyboard,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboard;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'Completa este campo.' : null,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}

/// Vista de error de carga con botón de reintento.
class AdminLoadError extends StatelessWidget {
  const AdminLoadError({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppColors.danger,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

/// Estado vacío reutilizable.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title, detail;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

InputDecoration adminFilterInputDecoration(String label) => InputDecoration(
  labelText: label,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: AppColors.border),
  ),
);

String formatRequirementStatus(String rawKey) {
  final clean = rawKey.trim().toLowerCase();
  switch (clean) {
    case 'cumplido':
    case 'cumplidos':
      return 'Cumplido';
    case 'en_proceso':
    case 'en proceso':
      return 'En Proceso';
    case 'pendiente':
    case 'pendientes':
      return 'Pendiente';
    default:
      if (clean.isEmpty) return 'Desconocido';
      return clean
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) {
            if (word.isEmpty) return '';
            return word[0].toUpperCase() + word.substring(1);
          })
          .join(' ');
  }
}

Map<String, int> parseAdminIntMap(dynamic value) {
  if (value is! Map) return {};
  return value.map(
    (key, val) => MapEntry(key.toString(), (val as num?)?.toInt() ?? 0),
  );
}

String adminErrorMessage(Object? error) {
  if (error is Exception) {
    return error.toString().replaceFirst('ApiException: ', '');
  }
  return 'No se pudo completar la solicitud.';
}

void showAdminSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

void showAdminDialogError(BuildContext context, Object error) {
  showDialog<void>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Error al guardar'),
      content: Text(adminErrorMessage(error)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}
