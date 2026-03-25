class LoginController {
  final List<Map<String, dynamic>> _users = [
    {
      "uid": "user_001",
      "username": "admin",
      "password": "admin123",
      "role": "Ketua",
      "teamId": "tim_1" 
    },
    {
      "uid": "user_002",
      "username": "budi",
      "password": "budi123",
      "role": "Anggota",
      "teamId": "tim_1"
    },
    {
      "uid": "user_003",
      "username": "testing",
      "password": "testing123",
      "role": "Ketua",
      "teamId": "tim_2" 
    },
    {
      "uid": "user_004",
      "username": "dart",
      "password": "dart123",
      "role": "Anggota",
      "teamId": "tim_2"
    },
  ];

  Map<String, dynamic>? login(String username, String password) {
    try {
      return _users.firstWhere(
        (u) => u['username'] == username && u['password'] == password
      );
    } catch (e) {
      return null;
    }
  }
}