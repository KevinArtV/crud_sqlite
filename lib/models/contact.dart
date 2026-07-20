class Contact {
  int? id;
  String? name;
  String? phone;
  String? email;
  bool isFavorite;

  Contact({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }
}
