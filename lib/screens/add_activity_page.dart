import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/facility_service.dart';
import '../utils/snackbar.dart';

class AddActivityPage extends StatefulWidget {
  const AddActivityPage({super.key});

  @override
  State<AddActivityPage> createState() => _AddActivityPageState();
}

class _AddActivityPageState extends State<AddActivityPage> {
  final nameCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lngCtrl = TextEditingController();
  final radiusCtrl = TextEditingController(text: '1000');
  final categoriesCtrl = TextEditingController();

  @override
  void dispose() {
    nameCtrl.dispose();
    latCtrl.dispose();
    lngCtrl.dispose();
    radiusCtrl.dispose();
    categoriesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Activity')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name')),
            TextField(
              controller: latCtrl,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngCtrl,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: radiusCtrl,
              decoration: const InputDecoration(labelText: 'Radius (m)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: categoriesCtrl,
              decoration: const InputDecoration(
                  labelText: 'Category IDs (comma separated)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final ids = categoriesCtrl.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  await facilityService.createFacility(
                    nameCtrl.text,
                    double.parse(latCtrl.text),
                    double.parse(lngCtrl.text),
                    double.tryParse(radiusCtrl.text) ?? 1000,
                    ids,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Activity added')));
                    Navigator.pop(context, true);
                  }
                } on DioException catch (e) {
                  if (context.mounted) {
                    showApiError(context, e, 'Create facility');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}
