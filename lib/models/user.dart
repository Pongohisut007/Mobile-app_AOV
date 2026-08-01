class User {
  final int id;
  final String username;
  final String email;
  final String password;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password
    });

    factory User.fromJson(Map<String , dynamic> json){
      return User(
          id: json["id"] as int,
          username: json["username"] as String,
          email: json["email"] as String,
          password: json["password"]  as String
      );
    }
}
