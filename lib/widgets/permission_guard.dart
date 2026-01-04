import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

/// Widget that checks if user has required permissions before rendering child
class PermissionGuard extends StatelessWidget {
  final UserRole? requiredRole;
  final List<UserRole>? allowedRoles;
  final Widget child;
  final Widget? fallback;
  final String? message;

  const PermissionGuard({
    super.key,
    this.requiredRole,
    this.allowedRoles,
    required this.child,
    this.fallback,
    this.message,
  }) : assert(
         requiredRole != null || allowedRoles != null,
         'Either requiredRole or allowedRoles must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;

        if (user == null) {
          return fallback ?? _buildAccessDenied(context);
        }

        final hasPermission = _checkPermission(user);

        if (hasPermission) {
          return child;
        }

        return fallback ?? _buildAccessDenied(context);
      },
    );
  }

  bool _checkPermission(UserModel user) {
    if (requiredRole != null) {
      return user.role == requiredRole;
    }

    if (allowedRoles != null) {
      return allowedRoles!.contains(user.role);
    }

    return false;
  }

  Widget _buildAccessDenied(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Access denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message ?? 'You do not have permission to access this feature.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mixin for checking permissions in widgets
mixin PermissionCheckerMixin<T extends StatefulWidget> on State<T> {
  bool hasRole(UserRole role) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userModel?.role == role;
  }

  bool hasAnyRole(List<UserRole> roles) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userRole = authProvider.userModel?.role;
    return userRole != null && roles.contains(userRole);
  }

  bool isAdmin() => hasRole(UserRole.admin);
  bool isCounsellor() => hasRole(UserRole.counsellor);
  bool isUser() => hasRole(UserRole.user);

  void showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You do not have permission to do that.')),
    );
  }
}
