import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import '../../../../models/models.dart';

class UsersCrudScreen extends ConsumerStatefulWidget {
  const UsersCrudScreen({super.key});

  @override
  ConsumerState<UsersCrudScreen> createState() => _UsersCrudScreenState();
}

class _UsersCrudScreenState extends ConsumerState<UsersCrudScreen> {
  List<AdminUser> _admins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/admin/users/fetch-all');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List;
        final list = rawList
            .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _admins = list;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleStatus(AdminUser admin) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put('/admin/users/toggle/${admin.id}');
      setState(() {
        _admins = _admins.map((a) {
          if (a.id == admin.id) {
            return a.copyWith(isActive: a.isActive == 1 ? 0 : 1);
          }
          return a;
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin & Staff Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _admins.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _admins.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final admin = _admins[index];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF16A34A).withOpacity(0.15),
                    child: const Icon(Icons.security, color: Color(0xFF16A34A)),
                  ),
                  title: Text(admin.fullName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${admin.email}'),
                      Text('Role: ${admin.role.toUpperCase()}'),
                    ],
                  ),
                  trailing: InkWell(
                    onTap: () => _toggleStatus(admin),
                    child: Chip(
                      label: Text(admin.isActive == 1 ? 'Active' : 'Disabled'),
                      backgroundColor: admin.isActive == 1
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      labelStyle: TextStyle(
                        color: admin.isActive == 1 ? Colors.green : Colors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
