import 'package:flutter/material.dart';

Image logoWidget(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 350,
    height: 350,
  );
}

Image logoWidgetSmall(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 250,
    height: 250,
  );
}

hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}

TextStyle btnText() {
  return const TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);
}

Image logoTop(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 150,
    height: 150,
  );
}

Image smllogoTop(String imageName) {
  return Image.asset(
    imageName,
    fit: BoxFit.fitWidth,
    width: 50,
    height: 50,
  );
}

ButtonStyle imgBtn() {
  return ButtonStyle(
    padding: MaterialStateProperty.all(const EdgeInsets.all(15)),
    backgroundColor: MaterialStateProperty.resolveWith((states) {
      if (states.contains(MaterialState.pressed)) {
        return Colors.black26;
      }
      return const Color.fromARGB(255, 0, 179, 250);
    }),
    shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
  );
}

TextStyle titles() {
  return const TextStyle(
      fontFamily: 'Comfortaa',
      fontSize: 25,
      fontWeight: FontWeight.bold,
      color: Colors.black);
}

EdgeInsetsGeometry screens(BuildContext context) {
  return EdgeInsets.fromLTRB(
      10, MediaQuery.of(context).size.height * 0.05, 10, 0);
}

TextField reusableTextField(String text, IconData icon, bool isPasswordTpe,
    TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: isPasswordTpe,
    enableSuggestions: !isPasswordTpe,
    autocorrect: !isPasswordTpe,
    cursorColor: Colors.black,
    style: const TextStyle(color: Colors.black),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      labelText: text,
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white.withOpacity(0.3),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.black, width: 2)),
    ),
    keyboardType: isPasswordTpe
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

Container signInButton(BuildContext context, bool isLogIn, Function onTap) {
  return Container(
    width: MediaQuery.of(context).size.width,
    height: 50,
    margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
    child: ElevatedButton(
      onPressed: () {
        onTap();
      },
      style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.black26;
            }
            return const Color.fromRGBO(184, 225, 241, 1);
          }),
          shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      child: Text(
        isLogIn ? 'LOG IN' : 'SIGN UP',
        style: const TextStyle(
            color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}

ElevatedButton selectBtn(
    BuildContext context, String title, String route, String img) {
  return ElevatedButton(
    onPressed: () {
      Navigator.pushNamed(context, route);
    },
    style: ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(15)),
      backgroundColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return Colors.black26;
        }
        return const Color.fromRGBO(184, 225, 241, 1);
      }),
      shape: MaterialStateProperty.all(RoundedRectangleBorder(
          side: const BorderSide(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(10))),
    ),
    child: Text(title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        )),
  );
}

Center bottomBtn(String title) {
  return Center(
      child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(184, 225, 241, 1),
            minimumSize: const Size.fromHeight(50),
          ),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          )));
}

TextStyle HeaderStyle() {
  return const TextStyle(
      color: Colors.black, fontSize: 42, fontWeight: FontWeight.normal);
}

TextStyle BodyStyle() {
  return const TextStyle(
      color: Colors.black, fontSize: 18, fontWeight: FontWeight.normal);
}

Container message() {
  return Container(
    margin: const EdgeInsets.all(12),
    height: 5 * 24.0,
    child: TextField(
      maxLines: 5,
      decoration: InputDecoration(
        hintText: "Enter a message",
        fillColor: Colors.grey[300],
        filled: true,
      ),
    ),
  );
}
