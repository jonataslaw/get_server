// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

class User {
  User({
    this.name,
    this.age,
    this.country,
    this.error,
  });

  String name;
  String age;
  String country;
  String error;

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
        name: json["name"],
        age: json["age"],
        country: json["Country"],
        error: json["Error"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "age": age,
        "Country": country,
        "Error": error,
      };
}
