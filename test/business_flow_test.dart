import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_queue_business/core/providers/queue_providers.dart';
import 'package:easy_queue_business/core/services/functions_service.dart';

void main() {
  test('selectedBusinessIdProvider initial state', () {
    final container = ProviderContainer();
    final bizId = container.read(selectedBusinessIdProvider);
    expect(bizId, '');
  });

  test('functionsServiceProvider initializes correctly', () {
    final container = ProviderContainer();
    final service = container.read(functionsServiceProvider);
    expect(service, isNotNull);
  });
}
