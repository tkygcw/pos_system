String? tablePromotion = 'tb_promotion ';

class PromotionFields {
  static List<String> values = [
    promotion_id,
    company_id,
    name,
    amount,
    specific_category,
    category_id,
    type,
    auto_apply,
    all_day,
    all_time,
    sdate,
    edate,
    stime,
    etime,
    created_at,
    updated_at,
    soft_delete
  ];

  static String promotion_id = 'promotion_id';
  static String company_id = 'company_id';
  static String name = 'name';
  static String amount = 'amount';
  static String specific_category = 'specific_category';
  static String category_id = 'category_id';
  static String type = 'type';
  static String auto_apply = 'auto_apply';
  static String all_day = 'all_day';
  static String all_time = 'all_time';
  static String sdate = 'sdate';
  static String edate = 'edate';
  static String stime = 'stime';
  static String etime = 'etime';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class Promotion{
  int? promotion_id;
  String? company_id;
  String? name;
  String? amount;
  String? specific_category;
  String? category_id;
  int? type;
  String? auto_apply;
  String? all_day;
  String? all_time;
  String? sdate;
  String? edate;
  String? stime;
  String? etime;
  String? created_at;
  String? updated_at;
  String? soft_delete;

  Promotion(
      {this.promotion_id,
        this.company_id,
        this.name,
        this.amount,
        this.specific_category,
        this.category_id,
        this.type,
        this.auto_apply,
        this.all_day,
        this.all_time,
        this.sdate,
        this.edate,
        this.stime,
        this.etime,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  Promotion copy({
    int? promotion_id,
    String? company_id,
    String? name,
    String? amount,
    String? specific_category,
    String? category_id,
    int? type,
    String? auto_apply,
    String? all_day,
    String? all_time,
    String? sdate,
    String? edate,
    String? stime,
    String? etime,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      Promotion(
          promotion_id: promotion_id ?? this.promotion_id,
          company_id: company_id ?? this.company_id,
          name: name ?? this.name,
          amount: amount ?? this.amount,
          specific_category: specific_category ?? this.specific_category,
          category_id: category_id ?? this.category_id,
          type: type ?? this.type,
          auto_apply: auto_apply ?? this.auto_apply,
          all_day: all_day ?? this.all_day,
          all_time: all_time ?? this.all_time,
          sdate: sdate ?? this.sdate,
          edate: edate ?? this.edate,
          stime: stime ?? this.stime,
          etime: etime ?? this.etime,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static Promotion fromJson(Map<String, Object?> json) => Promotion (
    promotion_id: json[PromotionFields.promotion_id] as int?,
    company_id: json[PromotionFields.company_id] as String?,
    name: json[PromotionFields.name] as String?,
    amount: json[PromotionFields.amount] as String?,
    specific_category: json[PromotionFields.specific_category] as String?,
    category_id: json[PromotionFields.category_id] as String?,
    type: json[PromotionFields.type] as int?,
    auto_apply: json[PromotionFields.auto_apply] as String?,
    all_day: json[PromotionFields.all_day] as String?,
    all_time: json[PromotionFields.all_time] as String?,
    sdate: json[PromotionFields.sdate] as String?,
    edate: json[PromotionFields.edate] as String?,
    stime: json[PromotionFields.stime] as String?,
    etime: json[PromotionFields.etime] as String?,
    created_at: json[PromotionFields.created_at] as String?,
    updated_at: json[PromotionFields.updated_at] as String?,
    soft_delete: json[PromotionFields.soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PromotionFields.promotion_id: promotion_id,
    PromotionFields.company_id: company_id,
    PromotionFields.name: name,
    PromotionFields.amount: amount,
    PromotionFields.specific_category: specific_category,
    PromotionFields.category_id: category_id,
    PromotionFields.type: type,
    PromotionFields.auto_apply: auto_apply,
    PromotionFields.all_day: all_day,
    PromotionFields.all_time: all_time,
    PromotionFields.sdate: sdate,
    PromotionFields.edate: edate,
    PromotionFields.stime: stime,
    PromotionFields.etime: etime,
    PromotionFields.created_at: created_at,
    PromotionFields.updated_at: updated_at,
    PromotionFields.soft_delete: soft_delete,
  };
}
