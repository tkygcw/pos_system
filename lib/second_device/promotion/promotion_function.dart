import 'package:intl/intl.dart';

import '../../database/pos_database.dart';
import '../../object/promotion.dart';

class PromotionFunction {
  PosDatabase _posDatabase = PosDatabase.instance;

  PromotionFunction();

  Future<List<Promotion>> getBranchPromotion() async {
    return await _posDatabase.readNotAutoApplyPromotion();
    // return promotions.where((promotion) {
    //   if (promotion.all_day == '1' && promotion.all_time == '1') {
    //     return true;
    //   } else if (promotion.all_day == '0' && promotion.all_time == '0') {
    //     return _isPromotionActiveToday(promotion);
    //   } else if (promotion.all_time == '1') {
    //     return _isDateWithinPromotionRange(DateTime.now(), promotion);
    //   } else {
    //     print("_isTimeWithinPromotionRange: ${_isTimeWithinPromotionRange(DateTime.now(), promotion)}");
    //     return _isTimeWithinPromotionRange(DateTime.now(), promotion);
    //   }
    // }).toList();
  }

  /// Checks if a promotion is active today.
  ///
  /// Returns:
  /// - `true` if today's date is within the promotion's date range and
  ///   the current time is within the promotion's time range.
  /// - `false` otherwise.
  bool _isPromotionActiveToday(Promotion promotion) {
    final now = DateTime.now();

    return _isDateWithinPromotionRange(now, promotion) &&
        _isTimeWithinPromotionRange(now, promotion);
  }

  /// Checks if a date is within a promotion's date range.
  ///
  /// Returns:
  /// - `true` if the given date is within the promotion's start and end dates.
  /// - `false` otherwise.
  bool _isDateWithinPromotionRange(DateTime date, Promotion promotion) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = dateFormat.parse(promotion.sdate!);
    final endDate = dateFormat.parse(promotion.edate!);

    return date.compareTo(startDate) >= 0 && date.compareTo(endDate) <=0;
  }

  /// Checks if a time is within a promotion's time range.
  ///
  /// Returns:
  /// - `true` if the given time is within the promotion's start and end times.
  /// - `false` otherwise.
  bool _isTimeWithinPromotionRange(DateTime time, Promotion promotion) {
    final timeFormat = DateFormat('HH:mm');
    final startTime = timeFormat.parse(promotion.stime!);
    final endTime = timeFormat.parse(promotion.etime!);

    final todayStartTime = DateTime(time.year, time.month, time.day,
        startTime.hour, startTime.minute);
    final todayEndTime = DateTime(time.year, time.month, time.day,
        endTime.hour, endTime.minute);

    return time.compareTo(todayStartTime) >= 0 &&
        time.compareTo(todayEndTime) < 0;
  }
}