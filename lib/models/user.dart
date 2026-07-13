class User
{
  int? id;
  String? name;
  String? email;

  User ({this.id, this.name, this.email});

  Map<String, dynamic> toMap()
  {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
    };
  }

  factory User.fromMap(Map<String, dynamic> map)
  {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String?,
      email: map['email'] as String?,
    );
  }
}

