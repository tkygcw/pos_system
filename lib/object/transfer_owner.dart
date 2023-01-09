String? tableTransferOwner = 'tb_transfer_owner ';

class TransferOwnerFields {
  static List<String> values = [
    transfer_owner_sqlite_id,
    transfer_owner_key,
    branch_id,
    device_id,
    transfer_from_user_id,
    transfer_to_user_id,
    cash_balance,
    sync_status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String transfer_owner_sqlite_id = 'transfer_owner_sqlite_id';
  static String transfer_owner_key = 'transfer_owner_key';
  static String branch_id = 'branch_id';
  static String device_id = 'device_id';
  static String transfer_from_user_id = 'transfer_from_user_id';
  static String transfer_to_user_id = 'transfer_to_user_id';
  static String cash_balance = 'cash_balance';
  static String sync_status = 'sync_status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class TransferOwner{
  int? transfer_owner_sqlite_id;
  String? transfer_owner_key;
  String? branch_id;
  String? device_id;
  String? transfer_from_user_id;
  String? transfer_to_user_id;
  String? cash_balance;
  int? sync_status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  String? fromUsername;
  String? toUsername;

  TransferOwner(
      {this.transfer_owner_sqlite_id,
        this.transfer_owner_key,
        this.branch_id,
        this.device_id,
        this.transfer_from_user_id,
        this.transfer_to_user_id,
        this.cash_balance,
        this.sync_status,
        this.created_at,
        this.updated_at,
        this.soft_delete,
        this.fromUsername,
        this.toUsername});

  TransferOwner copy({
    int? transfer_owner_sqlite_id,
    String? transfer_owner_key,
    String? branch_id,
    String? device_id,
    String? transfer_from_user_id,
    String? transfer_to_user_id,
    String? cash_balance,
    int? sync_status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      TransferOwner(
          transfer_owner_sqlite_id: transfer_owner_sqlite_id ?? this.transfer_owner_sqlite_id,
          transfer_owner_key: transfer_owner_key ?? this.transfer_owner_key,
          branch_id: branch_id ?? this.branch_id,
          device_id: device_id ?? this.device_id,
          transfer_from_user_id: transfer_from_user_id ?? this.transfer_from_user_id,
          transfer_to_user_id: transfer_to_user_id ?? this.transfer_to_user_id,
          cash_balance: cash_balance ?? this.cash_balance,
          sync_status: sync_status ?? this.sync_status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static TransferOwner fromJson(Map<String, Object?> json) => TransferOwner(
    transfer_owner_sqlite_id: json[TransferOwnerFields.transfer_owner_sqlite_id] as int?,
    transfer_owner_key: json[TransferOwnerFields.transfer_owner_key] as String?,
    branch_id: json[TransferOwnerFields.branch_id] as String?,
    device_id: json[TransferOwnerFields.device_id] as String?,
    transfer_from_user_id: json[TransferOwnerFields.transfer_from_user_id] as String?,
    transfer_to_user_id: json[TransferOwnerFields.transfer_to_user_id] as String?,
    cash_balance: json[TransferOwnerFields.cash_balance] as String?,
    sync_status: json[TransferOwnerFields.sync_status] as int?,
    created_at: json[TransferOwnerFields.created_at] as String?,
    updated_at: json[TransferOwnerFields.updated_at] as String?,
    soft_delete: json[TransferOwnerFields.soft_delete] as String?,
    fromUsername: json['name1'] as String?,
    toUsername: json['name2'] as String?
  );

  Map<String, Object?> toJson() => {
    TransferOwnerFields.transfer_owner_sqlite_id: transfer_owner_sqlite_id,
    TransferOwnerFields.transfer_owner_key: transfer_owner_key,
    TransferOwnerFields.branch_id: branch_id,
    TransferOwnerFields.device_id: device_id,
    TransferOwnerFields.transfer_from_user_id: transfer_from_user_id,
    TransferOwnerFields.transfer_to_user_id: transfer_to_user_id,
    TransferOwnerFields.cash_balance: cash_balance,
    TransferOwnerFields.sync_status: sync_status,
    TransferOwnerFields.created_at: created_at,
    TransferOwnerFields.updated_at: updated_at,
    TransferOwnerFields.soft_delete: soft_delete,
  };
}