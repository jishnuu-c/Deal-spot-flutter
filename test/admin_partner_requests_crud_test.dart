import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dealspot_flutter/features/admin/presentation/cruds/partner_requests_crud_screen.dart';
import 'package:dealspot_flutter/core/services/partner_request_repository.dart';
import 'package:dealspot_flutter/models/models.dart';

void main() {
  final sampleRequests = [
    PartnerRequest(
      id: 1,
      storeNameEn: 'Lulu Hypermarket',
      storeNameAr: 'لولو هايبر ماركت',
      applicantName: 'Mohammed Al-Rashid',
      applicantEmail: 'partner@luluhypermarket.com',
      applicantPhone: '+966 50 123 4567',
      cityNameEn: 'Riyadh',
      cityNameAr: 'الرياض',
      categoryNameEn: 'Hypermarkets',
      categoryNameAr: 'هايبر ماركت',
      crNumber: '1010998877',
      vatNumber: '300123456700003',
      website: 'https://luluhypermarket.com',
      descriptionEn: 'Major international retail hypermarket chain.',
      descriptionAr: 'سلسلة هايبر ماركت تجزئة دولية كبرى.',
      status: PartnerRequestStatus.PENDING,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PartnerRequest(
      id: 2,
      storeNameEn: 'Jarir Bookstore',
      storeNameAr: 'مكتبة جرير',
      applicantName: 'Fahad Al-Otaibi',
      applicantEmail: 'manager@jarir.com',
      applicantPhone: '+966 55 987 6543',
      cityNameEn: 'Jeddah',
      cityNameAr: 'جدة',
      categoryNameEn: 'Electronics & Books',
      categoryNameAr: 'إلكترونيات وكتب',
      crNumber: '4030112233',
      vatNumber: '300987654300003',
      status: PartnerRequestStatus.APPROVED,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    PartnerRequest(
      id: 3,
      storeNameEn: 'Panda Retail',
      storeNameAr: 'بنده للتجزئة',
      applicantName: 'Sarah Al-Ghamdi',
      applicantEmail: 'sarah@panda.com.sa',
      applicantPhone: '+966 54 333 2211',
      cityNameEn: 'Dammam',
      cityNameAr: 'الدمام',
      categoryNameEn: 'Groceries',
      categoryNameAr: 'بقالة ومواد تموينية',
      rejectionReason: 'Invalid Commercial Registration document.',
      status: PartnerRequestStatus.REJECTED,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        partnerRequestRepositoryProvider.overrideWith(
          (ref) => _FakePartnerRequestNotifier(sampleRequests),
        ),
      ],
      child: const MaterialApp(
        home: PartnerRequestsCrudScreen(),
      ),
    );
  }

  testWidgets('PartnerRequestsCrudScreen renders header, tabs, and pending card by default', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify Header
    expect(find.text('Merchant Partner Requests'), findsOneWidget);

    // Verify Tab counts & status pill
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);

    // Pending tab is selected by default -> Lulu Hypermarket visible
    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('Jarir Bookstore'), findsNothing);
  });

  testWidgets('PartnerRequestsCrudScreen tab switching filters correctly', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to Approved
    await tester.tap(find.text('Approved'));
    await tester.pumpAndSettle();

    expect(find.text('Jarir Bookstore'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsNothing);

    // Switch to Rejected
    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();

    expect(find.text('Panda Retail'), findsOneWidget);
    expect(find.text('Invalid Commercial Registration document.'), findsOneWidget);

    // Switch to All
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    expect(find.text('Lulu Hypermarket'), findsOneWidget);
    expect(find.text('Jarir Bookstore'), findsOneWidget);
    expect(find.text('Panda Retail'), findsOneWidget);
  });

  testWidgets('PartnerRequestsCrudScreen search filtering works', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to All tab first
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // Search for 'Jeddah'
    await tester.enterText(find.byType(TextField), 'Jeddah');
    await tester.pumpAndSettle();

    expect(find.text('Jarir Bookstore'), findsOneWidget);
    expect(find.text('Lulu Hypermarket'), findsNothing);
  });

  testWidgets('PartnerRequestsCrudScreen toggles view mode to Table view', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Switch to All tab
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // Click Table view toggle
    await tester.tap(find.text('Table'));
    await tester.pumpAndSettle();

    expect(find.byType(DataTable), findsOneWidget);
    expect(find.text('Store & Category'), findsOneWidget);
    expect(find.text('Applicant / Manager'), findsOneWidget);
    expect(find.text('CR & VAT'), findsOneWidget);
  });

  testWidgets('PartnerRequestsCrudScreen inspect details modal opens with comprehensive details', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Click Inspect Details on Lulu Hypermarket card
    await tester.tap(find.text('Inspect Details').first);
    await tester.pumpAndSettle();

    // Modal should be visible
    expect(find.text('Store Identity'), findsOneWidget);
    expect(find.text('Commercial & Legal'), findsOneWidget);
    expect(find.text('Applicant / Store Manager'), findsOneWidget);
    expect(find.text('Commercial Reg (CR):'), findsOneWidget);
    expect(find.text('1010998877'), findsWidgets);

    // Close modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Store Identity'), findsNothing);
  });
}

class _FakePartnerRequestNotifier extends StateNotifier<PartnerRequestState>
    implements PartnerRequestNotifier {
  _FakePartnerRequestNotifier(List<PartnerRequest> initial)
      : super(PartnerRequestState(requests: initial, isLoading: false));

  @override
  Future<void> fetchRequests({PartnerRequestStatus? status}) async {}

  @override
  List<PartnerRequest> getRequests({PartnerRequestStatus? status}) => state.requests;

  @override
  Future<PartnerRequest?> approveRequest(int id) async {
    return state.requests.firstWhere((r) => r.id == id);
  }

  @override
  Future<bool> rejectRequest(int id, String reason) async {
    return true;
  }

  @override
  Future<bool> submitApplication(PartnerRequest req) async => true;
}
