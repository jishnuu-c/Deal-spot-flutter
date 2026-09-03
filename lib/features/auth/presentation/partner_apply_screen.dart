import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/city_repository.dart';
import '../../../core/services/category_repository.dart';
import '../../../core/services/partner_request_repository.dart';
import '../../../core/utils/translation_service.dart';
import '../../../models/models.dart';

class PartnerApplyScreen extends ConsumerStatefulWidget {
  const PartnerApplyScreen({super.key});

  @override
  ConsumerState<PartnerApplyScreen> createState() => _PartnerApplyScreenState();
}

class _PartnerApplyScreenState extends ConsumerState<PartnerApplyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _applicantNameController = TextEditingController();
  final _applicantEmailController = TextEditingController();
  final _applicantPhoneController = TextEditingController();
  final _storeNameEnController = TextEditingController();
  final _storeNameArController = TextEditingController();
  final _crNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _descEnController = TextEditingController();
  final _descArController = TextEditingController();

  int? _selectedCityId;
  int? _selectedCategoryId;
  bool _submitting = false;

  @override
  void dispose() {
    _applicantNameController.dispose();
    _applicantEmailController.dispose();
    _applicantPhoneController.dispose();
    _storeNameEnController.dispose();
    _storeNameArController.dispose();
    _crNumberController.dispose();
    _vatNumberController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _descEnController.dispose();
    _descArController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select city and category.')),
      );
      return;
    }

    setState(() => _submitting = true);

    final req = PartnerRequest(
      id: 0,
      applicantName: _applicantNameController.text.trim(),
      applicantEmail: _applicantEmailController.text.trim(),
      applicantPhone: _applicantPhoneController.text.trim(),
      storeNameEn: _storeNameEnController.text.trim(),
      storeNameAr: _storeNameArController.text.trim(),
      descriptionEn: _descEnController.text.trim().isNotEmpty ? _descEnController.text.trim() : null,
      descriptionAr: _descArController.text.trim().isNotEmpty ? _descArController.text.trim() : null,
      cityId: _selectedCityId,
      categoryId: _selectedCategoryId,
      crNumber: _crNumberController.text.trim().isNotEmpty ? _crNumberController.text.trim() : null,
      vatNumber: _vatNumberController.text.trim().isNotEmpty ? _vatNumberController.text.trim() : null,
      website: _websiteController.text.trim().isNotEmpty ? _websiteController.text.trim() : null,
      contactAddress: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
    );

    final ok = await ref.read(partnerRequestRepositoryProvider.notifier).submitApplication(req);

    if (mounted) {
      setState(() => _submitting = false);
      if (ok) {
        final tr = ref.read(localizationsProvider);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Text(tr.get('app_title')),
              ],
            ),
            content: Text(tr.get('partner_request_success')),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/');
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(localizationsProvider);
    final isRtl = ref.watch(translationProvider) == AppLanguage.ar;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cities = ref.watch(cityRepositoryProvider).cities;
    final categories = ref.watch(categoryRepositoryProvider).where((c) => c.parentId == null).toList();

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isRtl ? 'انضم كشريك' : 'Partner With Us', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero banner card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF163E27), const Color(0xFF1E293B)]
                          : [const Color(0xFF065F46), const Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified, color: Colors.amber, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isRtl ? 'شبكة شركاء ديل سبوت' : 'DealSpot Partner Network',
                            style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRtl ? 'سجل متجرك واصل لملايين المتسوقين' : 'List Your Store & Reach Smart Shoppers',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr.get('partner_desc'),
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Authorized Manager Information
                _buildSectionHeader(Icons.person, isRtl ? '١. بيانات المدير المفوض' : '1. Manager Information'),
                const SizedBox(height: 12),
                _buildTextField(_applicantNameController, tr.get('applicant_name'), Icons.badge, true),
                const SizedBox(height: 12),
                _buildTextField(_applicantEmailController, tr.get('applicant_email'), Icons.email, true, isEmail: true),
                const SizedBox(height: 12),
                _buildTextField(_applicantPhoneController, tr.get('applicant_phone'), Icons.phone, true, isPhone: true),
                const SizedBox(height: 24),

                // 2. Store Profile & Location
                _buildSectionHeader(Icons.storefront, isRtl ? '٢. بيانات وهوية المتجر' : '2. Store Profile & Location'),
                const SizedBox(height: 12),
                _buildTextField(_storeNameEnController, tr.get('store_name_en'), Icons.store, true),
                const SizedBox(height: 12),
                _buildTextField(_storeNameArController, tr.get('store_name_ar'), Icons.store, true),
                const SizedBox(height: 12),

                // City dropdown
                DropdownButtonFormField<int?>(
                  value: _selectedCityId,
                  decoration: InputDecoration(
                    labelText: tr.get('operating_city'),
                    prefixIcon: const Icon(Icons.place, color: Color(0xFF16A34A), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: cities.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(isRtl ? c.nameAr : c.nameEn),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCityId = val),
                  validator: (v) => v == null ? 'Please select city' : null,
                ),
                const SizedBox(height: 12),

                // Category dropdown
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: tr.get('store_category'),
                    prefixIcon: const Icon(Icons.category, color: Color(0xFF16A34A), size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: categories.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(isRtl ? c.nameAr : c.nameEn),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (v) => v == null ? 'Please select category' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(_addressController, tr.get('contact_address'), Icons.location_on, false),
                const SizedBox(height: 24),

                // 3. Legal & Commercial Details
                _buildSectionHeader(Icons.gavel, isRtl ? '٣. البيانات التجارية والضريبية' : '3. Commercial & Legal Details'),
                const SizedBox(height: 12),
                _buildTextField(_crNumberController, tr.get('cr_number'), Icons.article, false),
                const SizedBox(height: 12),
                _buildTextField(_vatNumberController, tr.get('vat_number'), Icons.receipt_long, false),
                const SizedBox(height: 12),
                _buildTextField(_websiteController, tr.get('website_url'), Icons.language, false),
                const SizedBox(height: 12),
                _buildTextField(_descEnController, tr.get('store_desc_en'), Icons.description, false, maxLines: 2),
                const SizedBox(height: 12),
                _buildTextField(_descArController, tr.get('store_desc_ar'), Icons.description, false, maxLines: 2),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            tr.get('submit_partner_request'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF16A34A), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool required, {
    bool isEmail = false,
    bool isPhone = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        labelText: '$label ${required ? '*' : ''}',
        prefixIcon: Icon(icon, color: const Color(0xFF16A34A), size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label is required';
              }
              if (isEmail && !value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            }
          : null,
    );
  }
}
