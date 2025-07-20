import 'package:flutter_test/flutter_test.dart';
import 'package:xstream/services/vpn_config_service.dart';

void main() {
  setUp(() async {
    await VpnConfig.importFromJson('[]');
  });

  test('VpnNode serialization', () {
    final node = VpnNode(
      name: 'Node1',
      countryCode: 'US',
      configPath: '/tmp/config',
      serviceName: 'svc',
      enabled: false,
    );
    final json = node.toJson();
    final restored = VpnNode.fromJson(json);
    expect(restored.name, equals('Node1'));
    expect(restored.countryCode, equals('US'));
    expect(restored.configPath, equals('/tmp/config'));
    expect(restored.serviceName, equals('svc'));
    expect(restored.enabled, isFalse);
  });

  test('Add and remove node', () {
    final node = VpnNode(
      name: 'Node2',
      countryCode: 'CN',
      configPath: '/tmp/c',
      serviceName: 'svc2',
    );
    VpnConfig.addNode(node);
    expect(VpnConfig.getNodeByName('Node2')?.serviceName, 'svc2');
    VpnConfig.removeNode('Node2');
    expect(VpnConfig.getNodeByName('Node2'), isNull);
  });

  test('Export and import', () async {
    final node = VpnNode(
      name: 'Node3',
      countryCode: 'JP',
      configPath: '/tmp/j',
      serviceName: 'svc3',
    );
    VpnConfig.addNode(node);
    final jsonStr = VpnConfig.exportToJson();
    await VpnConfig.importFromJson(jsonStr);
    expect(VpnConfig.getNodeByName('Node3')?.serviceName, 'svc3');
  });
}
