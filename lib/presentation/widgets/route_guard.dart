import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class RouteGuard extends StatelessWidget {
  final Widget child;
  final bool requireAdmin;
  final bool requireSupervisor;
  final bool requireAttention;
  final bool requireCaller;
  final bool requireAuth;

  const RouteGuard({
    super.key,
    required this.child,
    this.requireAdmin = false,
    this.requireSupervisor = false,
    this.requireAttention = false,
    this.requireCaller = false,
    this.requireAuth = true,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (requireAuth && !auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const SizedBox.shrink();
    }

    if (requireAdmin && !auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    if (requireSupervisor && !auth.isSupervisor && !auth.isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    if (requireAttention && !auth.isAttentionUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    if (requireCaller && !auth.isCaller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      });
      return const SizedBox.shrink();
    }

    return child;
  }
}