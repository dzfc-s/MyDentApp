import '../models/doctor_absence.dart';
import 'base_provider.dart';

class DoctorAbsenceProvider extends BaseProvider<DoctorAbsence> {
  DoctorAbsenceProvider() : super("DoctorAbsences");

  @override
  DoctorAbsence fromJson(data) =>
      DoctorAbsence.fromJson(data as Map<String, dynamic>);
}
