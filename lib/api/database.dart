import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> fetchData() async {
  var url = Uri.parse('http://localhost/VETGO/api.php');
  var response = await http.post(url);
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    print(data);
  } else {
    print('Failed to load data');
  }
}
