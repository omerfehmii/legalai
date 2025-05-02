import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:legalai/core/theme/app_theme.dart'; // Import theme
import 'package:legalai/features/advisor/data/models/advisor_session.dart'; // Session model
import 'package:legalai/features/advisor/providers/advisor_providers.dart'; // Providers
import 'package:legalai/features/advisor/ui/screens/advisor_screen.dart'; // Advisor screen

class AdvisorHistoryScreen extends ConsumerWidget {
  const AdvisorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsState = ref.watch(advisorSessionsProvider);
    final sessionNotifier = ref.read(advisorSessionsProvider.notifier);
    final DateFormat formatter = DateFormat('dd MMM yyyy, HH:mm'); // Date formatter

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Görüşmeler'),
        titleTextStyle: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: false, // Align title to the left
        backgroundColor: Colors.white, // Or AppTheme.backgroundColor
        elevation: 1, // Add subtle elevation
        shadowColor: Colors.grey.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            tooltip: 'Yenile',
            onPressed: () => ref.refresh(advisorSessionsProvider), // Refresh the provider
          ),
        ],
      ),
      body: _buildBody(context, sessionsState, sessionNotifier, formatter, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to a new chat screen, clearing the previous one if necessary
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdvisorScreen()),
          );
        },
        label: const Text('Yeni Sohbet'),
        icon: const Icon(Icons.add_comment_outlined),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AdvisorSessionsState sessionsState,
    AdvisorSessionsNotifier sessionNotifier,
    DateFormat formatter,
    WidgetRef ref,
  ) {
    if (sessionsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessionsState.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  'Bir hata oluştu', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 5),
                Text(sessionsState.errorMessage!, textAlign: TextAlign.center),
             ]
          )
        ),
      );
    }

    if (sessionsState.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum_outlined, // Different icon
                size: 80,
                color: Colors.grey[350],
              ),
              const SizedBox(height: 20),
              Text(
                'Henüz kaydedilmiş bir görüşmeniz yok',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Yeni bir görüşme başlatmak için aşağıdaki butonu kullanın.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Display the list of sessions
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      itemCount: sessionsState.sessions.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, index) {
        final session = sessionsState.sessions[index];
        return _buildSessionTile(context, session, sessionNotifier, formatter, ref);
      },
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    AdvisorSession session,
    AdvisorSessionsNotifier sessionNotifier,
    DateFormat formatter,
    WidgetRef ref,
  ) {
    return Dismissible(
      key: Key(session.id), // Unique key for Dismissible
      direction: DismissDirection.endToStart, // Swipe direction
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Görüşmeyi Sil'),
              content: Text('\"${session.title}\" başlıklı görüşmeyi silmek istediğinizden emin misiniz?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false), // Return false
                  child: const Text('İPTAL'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.of(context).pop(true), // Return true
                  child: const Text('SİL'),
                ),
              ],
            );
          },
        ) ?? false; // Return false if dialog is dismissed
      },
      onDismissed: (direction) {
        // Delete the session if confirmed
        sessionNotifier.deleteAdvisorSession(session.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\"${session.title}\" silindi.'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(label: 'Geri Al', onPressed: () { 
              // TODO: Implement Undo functionality if needed (requires temporary storage)
              print('Undo not implemented yet');
            }),
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'Son güncelleme: ${formatter.format(session.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          // Navigate to the specific chat screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdvisorScreen(chatId: session.id),
            ),
          );
        },
      ),
    );
  }
} 