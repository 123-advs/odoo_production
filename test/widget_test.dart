import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';

import 'package:odoo_production/main.dart';

void main() {
  // GetStorage relies on path_provider, which uses a platform channel that
  // is unavailable under `flutter test`. Mock the channel to a temp dir so
  // GetStorage.init() doesn't throw MissingPluginException.
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    return Directory.systemTemp.createTempSync('gs_test').path;
  });

  setUpAll(() async {
    await GetStorage.init();
  });

  testWidgets('App boots to splash screen', (tester) async {
    await tester.pumpWidget(const OdooProductionApp());
    await tester.pump();
    expect(find.text('TCS MMS Worker'), findsOneWidget);

    // Tear down so SplashController's Timer doesn't trigger
    // "A Timer is still pending" after the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
