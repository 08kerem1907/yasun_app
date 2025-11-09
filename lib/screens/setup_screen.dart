import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kurulum ekranı artık gereksiz, kullanıcıyı doğrudan giriş ekranına yönlendiriyoruz.
    // Ancak, main.dart'ta hala bir rota olarak tanımlı olduğu için boş bir ekran bırakmak daha güvenli.
    // Kullanıcıya bir mesaj gösterip giriş ekranına yönlendirebiliriz.
    Future.microtask(() {
      Navigator.of(context).pushReplacementNamed('/login');
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
