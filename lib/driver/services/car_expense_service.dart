import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/car_expense.dart';

class CarExpenseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new car expense
  Future<CarExpense?> addExpense(CarExpense expense) async {
    try {
      final response =
          await _supabase
              .from('car_expenses')
              .insert(expense.toDatabase())
              .select()
              .single();

      return CarExpense.fromJson(response);
    } catch (e) {
      print('❌ Error adding expense: $e');
      rethrow;
    }
  }

  /// Update an existing expense
  Future<CarExpense?> updateExpense(CarExpense expense) async {
    try {
      if (expense.id == null) {
        throw Exception('Expense ID is required for update');
      }

      final response =
          await _supabase
              .from('car_expenses')
              .update(expense.toDatabase())
              .eq('id', expense.id!)
              .select()
              .single();

      return CarExpense.fromJson(response);
    } catch (e) {
      print('❌ Error updating expense: $e');
      rethrow;
    }
  }

  /// Delete an expense
  Future<void> deleteExpense(int expenseId) async {
    try {
      await _supabase.from('car_expenses').delete().eq('id', expenseId);
    } catch (e) {
      print('❌ Error deleting expense: $e');
      rethrow;
    }
  }

  /// Get all expenses for a driver
  Future<List<CarExpense>> getExpenses(int driverId) async {
    try {
      final response = await _supabase
          .from('car_expenses')
          .select()
          .eq('driver_id', driverId)
          .order('expense_date', ascending: false);

      return (response as List)
          .map((json) => CarExpense.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching expenses: $e');
      return [];
    }
  }

  /// Get expenses by date range
  Future<List<CarExpense>> getExpensesByDateRange(
    int driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase
          .from('car_expenses')
          .select()
          .eq('driver_id', driverId)
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      return (response as List)
          .map((json) => CarExpense.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching expenses by date range: $e');
      return [];
    }
  }

  /// Get expenses by type
  Future<List<CarExpense>> getExpensesByType(
    int driverId,
    String expenseType,
  ) async {
    try {
      final response = await _supabase
          .from('car_expenses')
          .select()
          .eq('driver_id', driverId)
          .eq('expense_type', expenseType)
          .order('expense_date', ascending: false);

      return (response as List)
          .map((json) => CarExpense.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error fetching expenses by type: $e');
      return [];
    }
  }

  /// Calculate total expenses for a date range
  Future<double> getTotalExpenses(
    int driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await getExpensesByDateRange(
        driverId,
        startDate,
        endDate,
      );
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    } catch (e) {
      print('❌ Error calculating total expenses: $e');
      return 0.0;
    }
  }

  /// Calculate total expenses by type
  Future<Map<String, double>> getExpensesByTypeBreakdown(
    int driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final expenses = await getExpensesByDateRange(
        driverId,
        startDate,
        endDate,
      );

      final breakdown = <String, double>{};
      for (var expense in expenses) {
        breakdown[expense.expenseType] =
            (breakdown[expense.expenseType] ?? 0.0) + expense.amount;
      }

      return breakdown;
    } catch (e) {
      print('❌ Error calculating expense breakdown: $e');
      return {};
    }
  }

  /// Calculate average fuel consumption
  Future<double?> getAverageFuelConsumption(
    int driverId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final fuelExpenses = await _supabase
          .from('car_expenses')
          .select()
          .eq('driver_id', driverId)
          .eq('expense_type', 'fuel')
          .gte('expense_date', startDate.toIso8601String().split('T')[0])
          .lte('expense_date', endDate.toIso8601String().split('T')[0])
          .not('fuel_liters', 'is', null)
          .not('distance_km', 'is', null);

      if (fuelExpenses.isEmpty) return null;

      final expenses =
          (fuelExpenses as List)
              .map((json) => CarExpense.fromJson(json))
              .toList();

      final totalLiters = expenses.fold<double>(
        0.0,
        (sum, expense) => sum + (expense.fuelLiters ?? 0.0),
      );
      final totalDistance = expenses.fold<double>(
        0.0,
        (sum, expense) => sum + (expense.distanceKm ?? 0.0),
      );

      if (totalDistance == 0) return null;

      return (totalLiters / totalDistance) * 100; // L/100km
    } catch (e) {
      print('❌ Error calculating average fuel consumption: $e');
      return null;
    }
  }

  /// Get monthly expense summary
  Future<Map<String, dynamic>> getMonthlySummary(
    int driverId,
    int year,
    int month,
  ) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final expenses = await getExpensesByDateRange(
        driverId,
        startDate,
        endDate,
      );

      final total = expenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      final breakdown = <String, double>{};

      for (var expense in expenses) {
        breakdown[expense.expenseType] =
            (breakdown[expense.expenseType] ?? 0.0) + expense.amount;
      }

      return {
        'total': total,
        'breakdown': breakdown,
        'count': expenses.length,
        'expenses': expenses,
      };
    } catch (e) {
      print('❌ Error fetching monthly summary: $e');
      return {'total': 0.0, 'breakdown': {}, 'count': 0, 'expenses': []};
    }
  }

  /// Stream expenses for real-time updates
  Stream<List<CarExpense>> watchExpenses(int driverId) {
    return _supabase
        .from('car_expenses')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .order('expense_date', ascending: false)
        .map((data) => data.map((json) => CarExpense.fromJson(json)).toList());
  }

  /// Reset all expenses for a driver (delete all records)
  Future<void> resetAllExpenses(int driverId) async {
    try {
      await _supabase.from('car_expenses').delete().eq('driver_id', driverId);
    } catch (e) {
      print('❌ Error resetting expenses: $e');
      rethrow;
    }
  }
}
