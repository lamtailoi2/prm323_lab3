import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/internship.dart';
import '../../../services/saved_internship_service.dart';

/// Watches saved internships for the currently signed-in user.
final savedInternshipsProvider = StreamProvider<List<Internship>>((ref) {
  final service = ref.watch(savedInternshipServiceProvider);
  return service.watchSaved();
});
