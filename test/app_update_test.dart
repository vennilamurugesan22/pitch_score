import 'package:flutter_test/flutter_test.dart';
import 'package:pitch_score/services/app_update_service.dart';

void main() {
  test('version compare', () {
    expect(AppUpdateService.compareVersions('1.0.0', '1.0.1'), lessThan(0));
    expect(AppUpdateService.compareVersions('1.10.0', '1.9.9'), greaterThan(0));
    expect(AppUpdateService.compareVersions('1.0.0+7', '1.0'), 0);
  });

  test('force when below min version', () {
    expect(
      AppUpdateService.decide(current: '1.0.0', latest: '1.2.0', minimum: '1.1.0'),
      UpdateType.force,
    );
  });

  test('optional when below latest, unless skipped', () {
    expect(
      AppUpdateService.decide(current: '1.0.0', latest: '1.1.0', minimum: '1.0.0'),
      UpdateType.optional,
    );
    expect(
      AppUpdateService.decide(
          current: '1.0.0', latest: '1.1.0', minimum: '1.0.0', skipped: '1.1.0'),
      UpdateType.none,
    );
  });

  test('force ignores skip', () {
    expect(
      AppUpdateService.decide(
          current: '1.0.0', latest: '2.0.0', minimum: '2.0.0', skipped: '2.0.0'),
      UpdateType.force,
    );
  });

  test('up to date', () {
    expect(
      AppUpdateService.decide(current: '1.1.0', latest: '1.1.0', minimum: '1.0.0'),
      UpdateType.none,
    );
  });
}
