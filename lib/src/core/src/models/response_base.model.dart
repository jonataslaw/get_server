class ResponseBaseModel {
  final bool success;
  final dynamic data;
  final String? error;

  ResponseBaseModel({required this.success, this.data, this.error});

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    json['success'] = success;
    json['data'] = data?.toJson();
    json['error'] = error;
    return json;
  }
}
