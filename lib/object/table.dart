import 'dart:ui';

import 'package:pos_system/object/table_use.dart';

String? tablePosTable = 'tb_table ';

class PosTableFields {
  static List<String> values = [
    table_sqlite_id,
    table_id,
    branch_id,
    number,
    seats,
    status,
    created_at,
    updated_at,
    soft_delete
  ];

  static String table_sqlite_id = 'table_sqlite_id';
  static String table_id = 'table_id';
  static String branch_id = 'branch_id';
  static String number = 'number';
  static String seats = 'seats';
  static String status = 'status';
  static String created_at = 'created_at';
  static String updated_at = 'updated_at';
  static String soft_delete = 'soft_delete';
}

class PosTable{
  int? table_sqlite_id;
  int? table_id;
  String? branch_id;
  String? number;
  String? seats;
  int? status;
  String? created_at;
  String? updated_at;
  String? soft_delete;
  double total_Amount = 0.0;
  String? group;
  String? cardColor;
  bool isSelected = false;

  PosTable(
      {this.table_sqlite_id,
        this.table_id,
        this.branch_id,
        this.number,
        this.seats,
        this.status,
        this.created_at,
        this.updated_at,
        this.soft_delete});

  PosTable copy({
    int? table_sqlite_id,
    int? table_id,
    String? branch_id,
    String? number,
    String? seats,
    int? status,
    String? created_at,
    String? updated_at,
    String? soft_delete,
  }) =>
      PosTable(
          table_sqlite_id: table_sqlite_id ?? this.table_sqlite_id,
          table_id: table_id ?? this.table_id,
          branch_id: branch_id ?? this.branch_id,
          number: number ?? this.number,
          seats: seats ?? this.seats,
          status: status ?? this.status,
          created_at: created_at ?? this.created_at,
          updated_at: updated_at ?? this.updated_at,
          soft_delete: soft_delete ?? this.soft_delete);

  static PosTable fromJson(Map<String, Object?> json) => PosTable  (
    table_sqlite_id: json[PosTableFields.table_sqlite_id] as int?,
    table_id: json[PosTableFields.table_id] as int?,
    branch_id: json[PosTableFields.branch_id] as String?,
    number: json[PosTableFields.number] as String?,
    seats: json[PosTableFields.seats] as String?,
    status: json[PosTableFields.status] as int?,
    created_at: json[PosTableFields.created_at] as String?,
    updated_at: json[PosTableFields.updated_at] as String?,
    soft_delete: json[PosTableFields .soft_delete] as String?,
  );

  Map<String, Object?> toJson() => {
    PosTableFields.table_sqlite_id: table_sqlite_id,
    PosTableFields.table_id: table_id,
    PosTableFields.branch_id: branch_id,
    PosTableFields.number: number,
    PosTableFields.seats: seats,
    PosTableFields.status: status,
    PosTableFields.created_at: created_at,
    PosTableFields.updated_at: updated_at,
    PosTableFields.soft_delete: soft_delete,
  };


}

