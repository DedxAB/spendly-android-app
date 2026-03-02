import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spendly/core/database/database_providers.dart';
import 'package:spendly/core/database/mappers.dart';
import 'package:spendly/features/investments/domain/entities/investment_entity.dart';
import 'package:spendly/features/investments/domain/repositories/investments_repository.dart';

class InvestmentsRepositoryImpl implements InvestmentsRepository {
  InvestmentsRepositoryImpl(this._ref);

  final Ref _ref;

  @override
  Future<void> addOrUpdate(InvestmentEntity investment) async {
    await _ref
        .read(appDatabaseProvider)
        .upsertInvestment(investmentToCompanion(investment));
  }

  @override
  Future<List<InvestmentEntity>> getAll() async {
    final rows = await _ref.read(appDatabaseProvider).getInvestments();
    return rows.map((e) => e.toEntity()).toList(growable: false);
  }

  @override
  Future<void> softDelete(String investmentId) async {
    await _ref.read(appDatabaseProvider).softDeleteInvestment(investmentId);
  }

  @override
  Stream<List<InvestmentEntity>> watchAll() {
    return _ref
        .read(appDatabaseProvider)
        .watchInvestments()
        .map((rows) => rows.map((e) => e.toEntity()).toList(growable: false));
  }
}

final investmentsRepositoryProvider = Provider<InvestmentsRepository>((ref) {
  return InvestmentsRepositoryImpl(ref);
});
