class CustomNotificationChannel {
  int channelId;
  String title, description, message, channelName, sound;

  CustomNotificationChannel({required this.channelId, required this.title, required this.description, required this.message, required this.channelName, required this.sound});

  factory CustomNotificationChannel.fromJson(Map<String, dynamic> json) {
    return CustomNotificationChannel(
        channelId: json['id'] as int,
        title: json['title'],
        description: json['description'],
        message: json['message'] as String,
        channelName: json['channel_name'] as String,
        sound: json['sound'] as String);
  }
}
