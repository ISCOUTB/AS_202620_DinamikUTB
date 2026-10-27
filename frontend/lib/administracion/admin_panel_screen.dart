import 'package:flutter/material.dart';
import 'package:frontend/core/responsive/breakpoints.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'admin_accounts_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_programs_screen.dart';
import 'admin_progress_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_requirements_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'admin_settings_screen.dart';
import 'admin_students_screen.dart';

enum AdminSection {
  dashboard('Dashboard', Icons.space_dashboard_outlined),
  estudiantes('Estudiantes', Icons.groups_2_outlined),
  programas('Programas académicos', Icons.school_outlined),
  requisitos('Requisitos de grado', Icons.fact_check_outlined),
  seguimiento('Seguimiento académico', Icons.trending_up_rounded),
  reportes('Reportes y estadísticas', Icons.bar_chart_rounded),
  administradores('Administradores', Icons.admin_panel_settings_outlined),
  configuracion('Configuración', Icons.tune_rounded);

  const AdminSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({
    super.key,
    required this.email,
    required this.onLogout,
    required this.service,
  });

  final String email;
  final VoidCallback onLogout;
  final AdminService service;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  AdminSection _selected = AdminSection.dashboard;
  final _globalSearch = TextEditingController();
  String? _studentSearch;
  bool _sidebarExpanded = true;

  @override
  void dispose() {
    _globalSearch.dispose();
    super.dispose();
  }

  void _navigate(AdminSection section) {
    setState(() {
      _selected = section;
      if (section == AdminSection.estudiantes) {
        _studentSearch = _globalSearch.text.trim();
      }
    });
    if (Breakpoints.of(context) == ScreenSize.compact) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final compact = Breakpoints.of(context) == ScreenSize.compact;

    return Scaffold(
      appBar: compact
          ? AppBar(
              title: const Text(
                'DinamikUTB',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  tooltip: 'Notificaciones',
                  onPressed: () => _message('No hay notificaciones nuevas.'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                _buildProfileButton(showLabels: false),
                const SizedBox(width: 8),
              ],
            )
          : null,
      drawer: compact
          ? Drawer(child: SafeArea(child: _buildSidebar(isCompactDrawer: true)))
          : null,
      body: Row(
        children: [
          if (!compact)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _sidebarExpanded ? 240 : 68,
              child: _buildSidebar(isCompactDrawer: false),
            ),
          Expanded(
            child: Column(
              children: [
                if (!compact) _buildTopbar(),
                Expanded(child: _buildCurrentBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentBody() => switch (_selected) {
    AdminSection.dashboard => AdminDashboardScreen(
      service: widget.service,
      onNavigate: _navigate,
    ),
    AdminSection.estudiantes => AdminStudentsScreen(
      service: widget.service,
      initialSearch: _studentSearch ?? '',
    ),
    AdminSection.programas => AdminProgramsScreen(service: widget.service),
    AdminSection.requisitos => AdminRequirementsScreen(service: widget.service),
    AdminSection.seguimiento => AdminProgressScreen(service: widget.service),
    AdminSection.reportes => AdminReportsScreen(service: widget.service),
    AdminSection.administradores => AdminAccountsScreen(
      service: widget.service,
      onLogout: widget.onLogout,
    ),
    AdminSection.configuracion => AdminSettingsScreen(email: widget.email),
  };

  Widget _buildSidebar({required bool isCompactDrawer}) {
    final showFull = isCompactDrawer || _sidebarExpanded;

    return Material(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (showFull) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DinamikUTB',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'GESTIÓN ACADÉMICA',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.9,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!isCompactDrawer)
                  IconButton(
                    iconSize: 18,
                    tooltip: _sidebarExpanded
                        ? 'Contraer menú'
                        : 'Expandir menú',
                    icon: Icon(
                      _sidebarExpanded
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                for (final section in AdminSection.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Tooltip(
                      message: showFull ? '' : section.label,
                      child: ListTile(
                        dense: true,
                        leading: Icon(section.icon, size: 20),
                        title: showFull
                            ? Text(
                                section.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                        selected: section == _selected,
                        selectedColor: AppColors.navy,
                        selectedTileColor: AppColors.surfaceLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onTap: () => _navigate(section),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout_rounded, size: 20),
            title: showFull
                ? const Text('Cerrar sesión', style: TextStyle(fontSize: 12))
                : null,
            onTap: widget.onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar() => Container(
    height: 64,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;

        return Row(
          children: [
            // Barra de búsqueda con ancho adaptativo (sin desbordamiento)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 260 : 180,
                minWidth: 120,
              ),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _globalSearch,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _navigate(AdminSection.estudiantes),
                  decoration: InputDecoration(
                    hintText: 'Buscar estudiantes...',
                    hintStyle: const TextStyle(fontSize: 12),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // En pantalla completa mostramos la información del semestre directamente
            if (isWide) ...[
              const Text(
                '2026 · Periodo académico',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: () => _message('No hay notificaciones nuevas.'),
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
              ),
              const SizedBox(width: 6),
            ],

            // Botón de perfil (en pantallas reducidas agrupa Semestre, correo y notificaciones)
            _buildProfileButton(showLabels: isWide),
          ],
        );
      },
    ),
  );

  Widget _buildProfileButton({required bool showLabels}) {
    return PopupMenuButton<String>(
      tooltip: 'Perfil y estado',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Administración',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const Divider(),
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 15,
                    color: AppColors.cyan,
                  ),
                  SizedBox(width: 6),
                  Text('Semestre: 2026', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 15,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Sin notificaciones nuevas',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          onTap: widget.onLogout,
          child: const Row(
            children: [
              Icon(Icons.logout_rounded, size: 16),
              SizedBox(width: 8),
              Text('Cerrar sesión', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceLow,
            child: Text(
              widget.email.isEmpty ? 'A' : widget.email[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          if (showLabels) ...[
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administración',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
