class CancelItemData {
  late int _userId;
  late int _orderDetailSqliteId;
  late bool _restock;
  late num _cancelQty;
  String? reason;

  // Private constructor
  CancelItemData._internal({
    required int userId,
    required int orderDetailSqliteId,
    required bool restock,
    required num cancelQty,
    this.reason,
  }) {
    _userId = userId;
    _orderDetailSqliteId = orderDetailSqliteId;
    _restock = restock;
    _cancelQty = cancelQty;
  }

  // The single instance
  static CancelItemData? _instance;

  // Access the instance without creating a new one
  static CancelItemData get instance {
    if (_instance == null) {
      throw Exception('CancelItemData has not been initialized yet');
    }
    return _instance!;
  }

  // Reset the singleton (for testing or reinitialization)
  static void reset() {
    _instance = null;
  }

  // Getters for private fields
  int get userId => _userId;
  int get orderDetailSqliteId => _orderDetailSqliteId;
  bool get restock => _restock;
  num get cancelQty => _cancelQty;

  factory CancelItemData.initializeDataFromJson(Map<String, Object?> json) {
    _instance = CancelItemData._internal(
        userId: json['userId'] as int,
        orderDetailSqliteId: json['orderDetailSqliteId'] as int,
        restock: json['restock'] as bool,
        cancelQty: json['cancelQty'] as num,
        reason: json['reason'] as String?
    );
    return _instance!;
  }
}