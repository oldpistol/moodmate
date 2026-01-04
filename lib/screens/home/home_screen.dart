import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../mood/mood_entry_screen.dart';
import '../mood/mood_history_screen.dart';
import '../mood/mood_trends_screen.dart';
import '../counsellor/counsellor_list_screen.dart';
import '../counsellor/support_requests_screen.dart';
import '../counsellor/counsellor_dashboard_screen.dart';
import '../counsellor/pending_requests_screen.dart';
import '../counsellor/counsellor_messages_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        return Scaffold(
          appBar: AppBar(
            title: const Text('MoodMate'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await authProvider.signOut();
                  }
                },
              ),
            ],
          ),
          body: user == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: colorScheme.primary,
                                    child: Text(
                                      user.name.isNotEmpty
                                          ? user.name[0].toUpperCase()
                                          : 'U',
                                      style: TextStyle(
                                        fontSize: 28,
                                        color: colorScheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back,',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        Text(
                                          user.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Chip(
                                label: Text(
                                  _getRoleDisplayName(user.role),
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: _getRoleColor(
                                  user.role,
                                  colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Dashboard content based on role
                      if (user.role == UserRole.user) ...[
                        _buildUserDashboard(context),
                      ] else if (user.role == UserRole.counsellor) ...[
                        _buildCounsellorDashboard(context),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.user:
        return 'User';
      case UserRole.counsellor:
        return 'Counsellor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Color _getRoleColor(UserRole role, ColorScheme colorScheme) {
    switch (role) {
      case UserRole.user:
        return colorScheme.secondaryContainer;
      case UserRole.counsellor:
        return colorScheme.tertiaryContainer;
      case UserRole.admin:
        return colorScheme.primaryContainer;
    }
  }

  Widget _buildUserDashboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Dashboard',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Mood tracking card
        _buildFeatureCard(
          context,
          icon: Icons.edit_note,
          title: 'Daily Mood Entry',
          subtitle: 'Track your mood today',
          color: colorScheme.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MoodEntryScreen()),
            );
          },
        ),
        const SizedBox(height: 12),

        // History card
        _buildFeatureCard(
          context,
          icon: Icons.history,
          title: 'Mood History',
          subtitle: 'View your past entries',
          color: colorScheme.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MoodHistoryScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Trends card
        _buildFeatureCard(
          context,
          icon: Icons.show_chart,
          title: 'Mood Trends',
          subtitle: 'Visualize your mood patterns',
          color: colorScheme.tertiary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MoodTrendsScreen()),
            );
          },
        ),
        const SizedBox(height: 12),

        // Counsellor card
        _buildFeatureCard(
          context,
          icon: Icons.support_agent,
          title: 'Contact Counsellor',
          subtitle: 'Connect with a professional',
          color: colorScheme.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CounsellorListScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Support requests card
        _buildFeatureCard(
          context,
          icon: Icons.question_answer,
          title: 'My Support Requests',
          subtitle: 'View your requests',
          color: colorScheme.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SupportRequestsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCounsellorDashboard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Counsellor Dashboard',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // My clients card
        _buildFeatureCard(
          context,
          icon: Icons.people_alt,
          title: 'My Clients',
          subtitle: 'View your assigned clients',
          color: colorScheme.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CounsellorDashboardScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Pending requests card
        _buildFeatureCard(
          context,
          icon: Icons.pending_actions,
          title: 'Pending Requests',
          subtitle: 'Accept new support requests',
          color: colorScheme.secondary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PendingRequestsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Messages card
        _buildFeatureCard(
          context,
          icon: Icons.message,
          title: 'Messages',
          subtitle: 'Chat with your clients',
          color: colorScheme.tertiary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CounsellorMessagesScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
