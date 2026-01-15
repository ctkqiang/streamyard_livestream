class StreamYardUser {
  final String firstName;
  final String lastName;

  StreamYardUser({required this.firstName, required this.lastName});

  factory StreamYardUser.fromJson(Map<String, dynamic> json) {
    return StreamYardUser(
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'firstName': firstName, 'lastName': lastName};
  }

  @override
  String toString() {
    return 'StreamYardUser{firstName: $firstName, lastName: $lastName}';
  }
}
