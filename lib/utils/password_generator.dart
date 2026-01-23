import 'dart:math';

class PasswordGenerator {
  static String generatePassword({
    required int length,
    required bool includeUppercase,
    required bool includeLowercase,
    required bool includeNumbers,
    required bool includeSpecialChars,
  }) {
    final String uppercaseLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final String lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    final String numbers = '0123456789';
    final String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String charSet = '';
    if (includeUppercase) charSet += uppercaseLetters;
    if (includeLowercase) charSet += lowercaseLetters;
    if (includeNumbers) charSet += numbers;
    if (includeSpecialChars) charSet += specialChars;

    if (charSet.isEmpty) {
      return '';
    }

    final Random random = Random.secure();
    String password = '';

    for (int i = 0; i < length; i++) {
      final int randomIndex = random.nextInt(charSet.length);
      password += charSet[randomIndex];
    }

    return password;
  }
}
