import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_repository.dart';
import '../../../../core/services/offer_repository.dart';
import '../../../../models/models.dart' as model;

class NotificationsCrudScreen extends ConsumerStatefulWidget {
  const NotificationsCrudScreen({super.key});

  @override
  ConsumerState<NotificationsCrudScreen> createState() => _NotificationsCrudScreenState();
}

class _NotificationsCrudScreenState extends ConsumerState<NotificationsCrudScreen> {
  final _titleEnCtrl = TextEditingController();
  final _titleArCtrl = TextEditingController();
  final _deepLinkCtrl = TextEditingController();
  String _selectedType = 'offer';
  String _selectedChannel = 'in_app';
  int? _selectedRefId;

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _deepLinkCtrl.dispose();
    super.dispose();
  }

  void _dispatch() {
    if (_titleEnCtrl.text.isEmpty || _titleArCtrl.text.isEmpty) return;

    ref.read(notificationRepositoryProvider.notifier).createNotification(
          101, // Fahad Al-Otaibi target customer (simulates push dispatch alert)
          _titleEnCtrl.text,
          _titleArCtrl.text,
          _selectedType,
          _selectedChannel,
          refId: _selectedRefId,
          refType: _selectedType,
          link: _deepLinkCtrl.text,
        );

    _titleEnCtrl.clear();
    _titleArCtrl.clear();
    _deepLinkCtrl.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification broadcast dispatched successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsList = ref.watch(notificationRepositoryProvider);
    final offers = ref.watch(offerRepositoryProvider).offers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Alert Notifications'),
      ),
      body: Row(
        children: [
          // Dispatch Form Column
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Compose Announcement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(controller: _titleEnCtrl, decoration: const InputDecoration(labelText: 'Title (EN)')),
                      const SizedBox(height: 12),
                      TextField(controller: _titleArCtrl, decoration: const InputDecoration(labelText: 'Title (AR)')),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Notification Type'),
                        items: const [
                          DropdownMenuItem(value: 'offer', child: Text('Offer discount promotion')),
                          DropdownMenuItem(value: 'flyer', child: Text('Flyer brochure release')),
                          DropdownMenuItem(value: 'coupon', child: Text('Promo coupon discount')),
                          DropdownMenuItem(value: 'system', child: Text('System alert message')),
                        ],
                        onChanged: (val) => setState(() => _selectedType = val ?? 'offer'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedChannel,
                        decoration: const InputDecoration(labelText: 'Delivery Channel'),
                        items: const [
                          DropdownMenuItem(value: 'in_app', child: Text('In-App Notification Feed')),
                          DropdownMenuItem(value: 'push', child: Text('Device Push Notification')),
                          DropdownMenuItem(value: 'email', child: Text('Email Alert')),
                        ],
                        onChanged: (val) => setState(() => _selectedChannel = val ?? 'in_app'),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedType == 'offer') ...[
                        DropdownButtonFormField<int?>(
                          value: _selectedRefId,
                          decoration: const InputDecoration(labelText: 'Select Target Offer link'),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('None')),
                            ...offers.map((o) => DropdownMenuItem<int?>(value: o.id, child: Text(o.titleEn))),
                          ],
                          onChanged: (val) => setState(() => _selectedRefId = val),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(controller: _deepLinkCtrl, decoration: const InputDecoration(labelText: 'Deep Link Path (Optional)')),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        onPressed: _dispatch,
                        icon: const Icon(Icons.send),
                        label: const Text('Dispatch Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // History log table
          Expanded(
            flex: 3,
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: notificationsList.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final notif = notificationsList[index];
                return ListTile(
                  leading: const Icon(Icons.history, color: Colors.grey),
                  title: Text(notif.titleEn),
                  subtitle: Text('Channel: ${notif.channel} | Type: ${notif.type} | Sent: ${notif.sentAt.split("T")[0]}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () {
                      ref.read(notificationRepositoryProvider.notifier).deleteNotification(notif.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
