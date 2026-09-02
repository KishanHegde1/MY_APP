import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:my_app_flutter/features/local_rides/presentation/screens/map_location_picker_screen.dart';
import 'package:my_app_flutter/shared/models/location_model.dart';

void main() {
  testWidgets('returns the exact center pin only after explicit confirmation', (
    tester,
  ) async {
    const target = LatLng(12.9279234, 77.6271071);
    LocationModel? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            key: const Key('open-picker'),
            onPressed: () async {
              selected = await Navigator.of(context).push<LocationModel>(
                MaterialPageRoute<LocationModel>(
                  builder: (_) => MapLocationPickerScreen(
                    reverseGeocoder: (_, _) async => 'Exact pickup address',
                    mapBuilder:
                        (
                          context, {
                          required initialCameraPosition,
                          required onCameraMove,
                          required onCameraIdle,
                        }) => Center(
                          child: FilledButton(
                            key: const Key('move-test-map'),
                            onPressed: () {
                              onCameraMove(
                                const CameraPosition(target: target, zoom: 17),
                              );
                              onCameraIdle();
                            },
                            child: const Text('Move map'),
                          ),
                        ),
                  ),
                ),
              );
            },
            child: const Text('Open picker'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('open-picker')));
    await tester.pumpAndSettle();
    expect(selected, isNull);

    await tester.tap(find.byKey(const Key('move-test-map')));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(find.text('Exact pickup address'), findsOneWidget);

    await tester.tap(find.byKey(const Key('location-picker-confirm')));
    await tester.pumpAndSettle();

    expect(selected?.latitude, target.latitude);
    expect(selected?.longitude, target.longitude);
    expect(selected?.label, 'Exact pickup address');
  });
}
