import 'package:spendly/features/investments/domain/entities/investment_entity.dart';

abstract class InvestmentsRepository {
  Stream<List<InvestmentEntity>> watchAll();

  Future<List<InvestmentEntity>> getAll();

  Future<void> addOrUpdate(InvestmentEntity investment);

  Future<void> softDelete(String investmentId);
}
