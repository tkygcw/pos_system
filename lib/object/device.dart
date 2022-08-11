class Device{
  int? deviceID;
  String? name;
  int? status;

  Device({this.status,this.name,this.deviceID});

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      status: json['status'],
      name: json['name'] as String,
      deviceID: json['device_id'],


    );
  }
}