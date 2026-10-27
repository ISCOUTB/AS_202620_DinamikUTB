import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/usuarios/account_screen.dart';
import 'package:frontend/administracion/service/admin_service.dart';
import 'widgets/admin_common_widgets.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({
    super.key,
    required this.service,
    required this.onLogout,
  });

  final AdminService service;
  final VoidCallback onLogout;

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsPageState();
}

class _AdminAccountsPageState extends State<AdminAccountsScreen> {
  late Future<List<AdminAccount>> _future = widget.service
      .cuentasAdministrativas();

  void _refresh() =>
      setState(() => _future = widget.service.cuentasAdministrativas());

  Future<void> _createAccount(BuildContext context) async {
    final key = GlobalKey<FormState>();
    final email = TextEditingController();
    final password = TextEditingController();
    var role = 'coordinador';

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear cuenta de gestión'),
          content: SizedBox(
            width: 430,
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminFormField(
                    controller: email,
                    label: 'Correo institucional',
                  ),
                  AdminFormField(
                    controller: password,
                    label: 'Contraseña temporal (mínimo 12 caracteres)',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    borderRadius: BorderRadius.circular(10),
                    decoration: adminFilterInputDecoration('Rol asignado'),
                    items: const [
                      DropdownMenuItem(
                        value: 'coordinador',
                        child: Text('Coordinador'),
                      ),
                      DropdownMenuItem(
                        value: 'administrador',
                        child: Text('Administrador'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => role = value ?? 'coordinador'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                if (password.text.length < 12) {
                  showAdminDialogError(
                    context,
                    Exception(
                      'La contraseña debe tener al menos 12 caracteres.',
                    ),
                  );
                  return;
                }
                try {
                  await widget.service.crearCuenta(
                    email: email.text.trim(),
                    password: password.text,
                    rol: role,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (error) {
                  if (context.mounted) showAdminDialogError(context, error);
                }
              },
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );

    email.dispose();
    password.dispose();
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) => AdminPageFrame(
    title: 'Cuentas y administradores',
    subtitle:
        'Verifica la identidad por un canal institucional antes de activar cuentas o emitir recuperaciones.',
    trailing: FilledButton.icon(
      onPressed: () => _createAccount(context),
      icon: const Icon(Icons.person_add_alt_1, size: 16),
      label: const Text('Agregar cuenta de gestión'),
    ),
    children: [
      FutureBuilder<List<AdminAccount>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AdminLoadError(
              message: adminErrorMessage(snapshot.error),
              retry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.data!.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: 'No hay cuentas',
              detail: 'La base de datos no contiene usuarios administrativos.',
            );
          }
          return Column(
            children: [
              for (final account in snapshot.data!)
                Card(
                  elevation: 0.5,
                  margin: const EdgeInsets.only(bottom: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.surfaceLow,
                      child: Text(account.email[0].toUpperCase()),
                    ),
                    title: Text(
                      account.email,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${account.rol} · ${account.codigo ?? 'Cuenta de gestión'}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AdminStatusTag(account.activo ? 'Activo' : 'Inactivo'),
                        PopupMenuButton<String>(
                          tooltip: 'Administrar cuenta',
                          onSelected: (value) =>
                              _accountAction(context, account, value),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: account.activo ? 'disable' : 'enable',
                              child: Text(
                                account.activo
                                    ? 'Desactivar cuenta'
                                    : 'Activar cuenta',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'role_admin',
                              child: Text('Asignar administrador'),
                            ),
                            const PopupMenuItem(
                              value: 'role_coord',
                              child: Text('Asignar coordinación'),
                            ),
                            const PopupMenuItem(
                              value: 'reset',
                              child: Text('Emitir enlace de restablecimiento'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Future<void> _accountAction(
    BuildContext context,
    AdminAccount account,
    String action,
  ) async {
    if (action == 'reset') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Verificar identidad'),
          content: Text(
            'Confirma por un canal institucional externo que ${account.email} es la persona solicitante. El enlace será válido por 15 minutos y solo podrá usarse una vez.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Emitir enlace'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      try {
        final token = await widget.service.emitirRecuperacion(account.id);
        final uri = Uri.base.replace(queryParameters: {'reset_token': token});
        if (!context.mounted) return;

        await showDialog<void>(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Text('Enlace de un solo uso'),
            content: SelectableText(uri.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cerrar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AccountScreen(
                        page: AccountPage.restablecer,
                        token: token,
                        onCompleted: () {
                          widget.onLogout();
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Restablecer ahora'),
              ),
            ],
          ),
        );
      } catch (error) {
        if (context.mounted) {
          showAdminSnackBar(context, adminErrorMessage(error));
        }
      }
      return;
    }

    final nextRole = action == 'role_admin'
        ? 'administrador'
        : action == 'role_coord'
        ? 'coordinador'
        : account.rol;
    final active = action == 'disable'
        ? false
        : action == 'enable'
        ? true
        : account.activo;

    try {
      await widget.service.actualizarCuenta(
        account.id,
        rol: nextRole,
        activo: active,
      );
      if (context.mounted) {
        showAdminSnackBar(context, 'Cuenta actualizada.');
        _refresh();
      }
    } catch (error) {
      if (context.mounted) showAdminSnackBar(context, adminErrorMessage(error));
    }
  }
}
