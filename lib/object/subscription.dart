String? tableSubscription = 'tb_subscription';

class SubscriptionFields {
  static List<String> values = [
    subscription_sqlite_id,
    id,
    company_id,
    subscription_plan_id,
    subscribe_package,
    subscribe_fee,
    duration,
    branch_amount,
    start_date,
    end_date,
    created_at
  ];

  static String subscription_sqlite_id = 'subscription_sqlite_id';
  static String id = 'id';
  static String company_id = 'company_id';
  static String subscription_plan_id = 'subscription_plan_id';
  static String subscribe_package = 'subscribe_package';
  static String subscribe_fee = 'subscribe_fee';
  static String duration = 'duration';
  static String branch_amount = 'branch_amount';
  static String start_date = 'start_date';
  static String end_date = 'end_date';
  static String created_at = 'created_at';
}

class Subscription {
  int? subscription_sqlite_id;
  int? id;
  String? company_id;
  String? subscription_plan_id;
  String? subscribe_package;
  String? subscribe_fee;
  String? duration;
  int? branch_amount;
  String? start_date;
  String? end_date;
  String? created_at;

  Subscription(
      {this.subscription_sqlite_id,
        this.id,
        this.company_id,
        this.subscription_plan_id,
        this.subscribe_package,
        this.subscribe_fee,
        this.duration,
        this.branch_amount,
        this.start_date,
        this.end_date,
        this.created_at});

  Subscription copy({
    int? subscription_sqlite_id,
    int? id,
    String? company_id,
    String? subscription_plan_id,
    String? subscribe_package,
    String? subscribe_fee,
    String? duration,
    int? branch_amount,
    String? start_date,
    String? end_date,
    String? created_at
  }) =>
      Subscription(
          subscription_sqlite_id: subscription_sqlite_id ?? this.subscription_sqlite_id,
          id: id ?? this.id,
          company_id: company_id ?? this.company_id,
          subscription_plan_id: subscription_plan_id ?? this.subscription_plan_id,
          subscribe_package: subscribe_package ?? this.subscribe_package,
          subscribe_fee: subscribe_fee ?? this.subscribe_fee,
          duration: duration ?? this.duration,
          branch_amount: branch_amount ?? this.branch_amount,
          start_date: start_date ?? this.start_date,
          end_date: end_date ?? this.end_date,
          created_at: created_at ?? this.created_at);

  static Subscription fromJson(Map<String, Object?> json) => Subscription(
    subscription_sqlite_id: json[SubscriptionFields.subscription_sqlite_id] as int?,
    id: json[SubscriptionFields.id] as int?,
    company_id: json[SubscriptionFields.company_id] as String?,
    subscription_plan_id: json[SubscriptionFields.subscription_plan_id] as String?,
    subscribe_package: json[SubscriptionFields.subscribe_package] as String?,
    subscribe_fee: json[SubscriptionFields.subscribe_fee] as String?,
    duration: json[SubscriptionFields.duration] as String?,
    branch_amount: json[SubscriptionFields.branch_amount] as int?,
    start_date: json[SubscriptionFields.start_date] as String?,
    end_date: json[SubscriptionFields.end_date] as String?,
    created_at: json[SubscriptionFields.created_at] as String?
  );

  Map<String, Object?> toJson() => {
    SubscriptionFields.subscription_sqlite_id: subscription_sqlite_id,
    SubscriptionFields.id: id,
    SubscriptionFields.company_id: company_id,
    SubscriptionFields.subscription_plan_id: subscription_plan_id,
    SubscriptionFields.subscribe_package: subscribe_package,
    SubscriptionFields.subscribe_fee: subscribe_fee,
    SubscriptionFields.duration: duration,
    SubscriptionFields.branch_amount: branch_amount,
    SubscriptionFields.start_date: start_date,
    SubscriptionFields.end_date: end_date,
    SubscriptionFields.created_at: created_at,
  };
}