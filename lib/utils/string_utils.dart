
import 'dart:math';

class StringUtils{
  static String randomString(int length) {
    final _random = Random();
    const _availableChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';
    final randomString = List.generate(length, (index) => _availableChars[_random.nextInt(_availableChars.length)]).join();
    return randomString;
  }
}