import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/hr_company_models.dart';
import '../repository/hr_company_repository.dart';

final hrCompanyRepositoryProvider = Provider<HrCompanyRepository>(
  (_) => HrCompanyRepository(),
);

class HrCompanyNotifier extends AsyncNotifier<HrCompanySettings> {
  @override
  Future<HrCompanySettings> build() => _fetch();

  Future<HrCompanySettings> _fetch() =>
      ref.read(hrCompanyRepositoryProvider).fetchAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final hrCompanyProvider =
    AsyncNotifierProvider<HrCompanyNotifier, HrCompanySettings>(
  HrCompanyNotifier.new,
);
