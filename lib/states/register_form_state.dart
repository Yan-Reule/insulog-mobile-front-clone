import 'package:flutter/material.dart';
import 'package:insulog/services/api/auth_service.dart';
import 'package:insulog/widgets/app_notification.dart';

class RegisterFormState extends ChangeNotifier {
  RegisterFormState() {
    usernameController.addListener(_validateUsername);
    lastnameController.addListener(_validateLastname);
    emailController.addListener(_validateEmail);
    passwordController.addListener(_validatePassword);
  }

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? usernameError;
  String? emailError;
  String? passwordError;
  String? lastnameError;

  String get username => usernameController.text;
  String get email => emailController.text;
  String get password => passwordController.text;
  String get lastname => lastnameController.text;

  bool isClicked = false;
  bool isLoading = false;
  String? registerError;

  List<String> get formErrors => [
    if (usernameError != null) usernameError!,
    if (lastnameError != null) lastnameError!,
    if (emailError != null) emailError!,
    if (passwordError != null) passwordError!,
  ];

  Future<void> register(BuildContext context) async {
    if (isLoading) return;
    isClicked = true;
    _validateUsername();
    _validateLastname();
    _validateEmail();
    _validatePassword();

    if (formErrors.isNotEmpty) {
      notifyListeners();
      return;
    }

    isLoading = true;
    registerError = null;
    usernameError = null;
    lastnameError = null;
    emailError = null;
    passwordError = null;

    try {
      await AuthService().register(username, lastname, email, password);
      isLoading = false;
      registerError = null;
      Navigator.pop(context, '/login');
    } on AuthException catch (e) {
      registerError = e.message;
      isLoading = false;

      AppNotification.error(context, e.message);

      if (e.statusCode == 400) {
        username.isEmpty ? usernameError = 'Campo obrigatorio' : null;
        email.isEmpty ? emailError = 'Campo obrigatorio' : null;
        password.isEmpty ? passwordError = 'Campo obrigatorio' : null;
      }

      if (e.statusCode == 409) {
        registerError = "Ja existe um usuario com esse e-mail";
      }
    } catch (_) {
      registerError = 'Erro inesperado.';
      isLoading = false;
      usernameError = null;
      lastnameError = null;
      emailError = null;
      passwordError = null;

      AppNotification.error(context, 'Erro inesperado.');
    }

    notifyListeners();
  }

  void _validateUsername() {
    if (username.isEmpty && !isClicked) {
      usernameError = null;
    } else if (username.isEmpty && isClicked) {
      usernameError = 'Campo obrigatorio';
    } else if (username.length < 3) {
      usernameError = 'O nome deve ter pelo menos 3 caracteres';
    } else {
      usernameError = null;
    }
    notifyListeners();
  }

  void _validateLastname() {
    if (lastname.isEmpty) {
      lastnameError = null;
    } else if (lastname.length < 3) {
      lastnameError = 'O sobrenome deve ter pelo menos 3 caracteres';
    } else {
      lastnameError = null;
    }
    notifyListeners();
  }

  void _validateEmail() {
    if (email.isEmpty && !isClicked) {
      emailError = null;
    } else if (email.isEmpty && isClicked) {
      emailError = 'Campo obrigatorio';
    } else if (!RegExp(
      r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$',
    ).hasMatch(email)) {
      emailError = 'Digite um email valido';
    } else {
      emailError = null;
    }
    notifyListeners();
  }

  void _validatePassword() {
    if (password.isEmpty && !isClicked) {
      passwordError = null;
    } else if (password.isEmpty && isClicked) {
      passwordError = 'Campo obrigatorio';
    } else if (password.length < 3) {
      passwordError = 'A senha deve ter pelo menos 3 caracteres';
    } else {
      passwordError = null;
    }
    notifyListeners();
  }

  void clear() {
    usernameController.clear();
    lastnameController.clear();
    emailController.clear();
    passwordController.clear();
    registerError = null;
    isLoading = false;
    usernameError = null;
    lastnameError = null;
    emailError = null;
    passwordError = null;
  }

  @override
  void dispose() {
    usernameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
