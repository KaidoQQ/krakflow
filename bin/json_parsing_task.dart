import 'dart:convert';

void main() {
  print("--- Zadanie 1: Odczyt danych z JSON ---");

  // A: Lista liczb
  print("\nA. Lista liczb:");
  String jsonA = '[1, 5, 8, 3, 2]';
  List<dynamic> listA = jsonDecode(jsonA);
  int sumA = 0;
  for (var number in listA) {
    print(number);
    sumA += number as int;
  }
  print("Suma: $sumA");

  // B: Obiekt z listą
  print("\nB. Obiekt z listą:");
  String jsonB = '{"group": "Dart", "students": ["Anna", "Jan", "Piotr"]}';
  Map<String, dynamic> mapB = jsonDecode(jsonB);
  print("Grupa: ${mapB['group']}");
  List<dynamic> students = mapB['students'];
  print("Studenci: ${students.join(', ')}");

  // C: Zagnieżdżone obiekty
  print("\nC. Zagnieżdżone obiekty:");
  String jsonC = '{"product": {"name": "Laptop", "price": 3500}}';
  Map<String, dynamic> mapC = jsonDecode(jsonC);
  Map<String, dynamic> product = mapC['product'];
  print("Nazwa: ${product['name']}");
  print("Cena: ${product['price']}");
}
