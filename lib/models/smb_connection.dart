class SmbConnection {
  final String id;
  final String name;
  final String host;
  final String shareName;
  final String username;
  final String password;
  final String? domain;

  SmbConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.shareName,
    required this.username,
    required this.password,
    this.domain,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'shareName': shareName,
        'username': username,
        'password': password,
        'domain': domain,
      };

  factory SmbConnection.fromJson(Map<String, dynamic> json) => SmbConnection(
        id: json['id'],
        name: json['name'],
        host: json['host'],
        shareName: json['shareName'],
        username: json['username'],
        password: json['password'],
        domain: json['domain'],
      );
}
