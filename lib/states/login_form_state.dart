import 'package:flutter/material.dart';
import 'package:insulog/globals.dart';
import 'package:insulog/services/api/auth_service.dart';
import 'package:insulog/services/local/saved_login_service.dart';
import 'package:insulog/widgets/app_notification.dart';

class LoginFormState extends ChangeNotifier {
  LoginFormState() {
    _lastUsernameText = usernameController.text;
    _lastPasswordText = passwordController.text;
    usernameController.addListener(_handleUsernameChanged);
    passwordController.addListener(_handlePasswordChanged);
  }

  final SavedLoginService _savedLoginService = SavedLoginService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String get username => usernameController.text;
  String get password => passwordController.text;

  bool isClicked = false;
  bool isLoading = false;

  String? usernameValidationError;
  String? passwordValidationError;
  String? usernameAuthError;
  String? passwordAuthError;
  String? loginError;

  late String _lastUsernameText;
  late String _lastPasswordText;

  String? get usernameError => usernameAuthError ?? usernameValidationError;
  String? get passwordError => passwordAuthError ?? passwordValidationError;

  Future<void> logar(BuildContext context) async {
    isClicked = true;
    _validateUsername();
    _validatePassword();

    if (usernameError != null || passwordError != null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    loginError = null;
    usernameAuthError = null;
    passwordAuthError = null;
    notifyListeners();

    try {
      final loginData = await AuthService().login(username, password);
      await _savedLoginService.saveCredentials(
        userId: loginData.userId,
        username: username,
        password: password,
      );

      Globals().setUserId(loginData.userId);
      Globals().setUsername(username);

      isLoading = false;
      loginError = null;

      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      loginError = e.message;
      isLoading = false;

      AppNotification.error(context, e.message);

      if (e.statusCode == 401) {
        usernameAuthError = 'Usuario incorreto';
        passwordAuthError = 'Senha incorreta';
      } else {
        usernameAuthError = null;
        passwordAuthError = null;
      }
    } catch (_) {
      loginError = 'Erro inesperado.';
      isLoading = false;
      usernameAuthError = null;
      passwordAuthError = null;

      AppNotification.error(context, 'Erro inesperado.');
    }

    notifyListeners();
  }

  Future<bool> tryAutoLogin(BuildContext context) async {
    final savedCredentials = await _savedLoginService.getCredentials();

    if (savedCredentials == null) {
      return false;
    }

    usernameController.text = savedCredentials.username;
    passwordController.text = savedCredentials.password;
    _lastUsernameText = usernameController.text;
    _lastPasswordText = passwordController.text;
    isClicked = true;
    isLoading = true;
    loginError = null;
    usernameAuthError = null;
    passwordAuthError = null;
    notifyListeners();

    try {
      final loginData = await AuthService().login(
        savedCredentials.username,
        savedCredentials.password,
      );
      Globals().setUserId(loginData.userId);
      Globals().setUsername(savedCredentials.username);
      isLoading = false;
      notifyListeners();

      if (!context.mounted) return true;

      Navigator.pushReplacementNamed(context, '/home');
      return true;
    } on AuthException {
      await _savedLoginService.clearCredentials();
      Globals().clearUsername();
      isClicked = false;
      isLoading = false;
      usernameAuthError = null;
      passwordAuthError = null;
      loginError = null;
      notifyListeners();
      return false;
    } catch (_) {
      Globals().clearUsername();
      isClicked = false;
      isLoading = false;
      loginError = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> cadastrar(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

    await Navigator.pushNamed(context, '/register');

    if (!context.mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void _handleUsernameChanged() {
    if (usernameController.text == _lastUsernameText) return;

    _lastUsernameText = usernameController.text;
    usernameAuthError = null;
    _validateUsername();
  }

  void _handlePasswordChanged() {
    if (passwordController.text == _lastPasswordText) return;

    _lastPasswordText = passwordController.text;
    passwordAuthError = null;
    _validatePassword();
  }

  void _validateUsername() {
    if (username.isEmpty && !isClicked) {
      usernameValidationError = null;
    } else if (username.isEmpty && isClicked) {
      usernameValidationError = 'Campo obrigatorio';
    } else if (username.length < 3) {
      usernameValidationError = 'O nome deve ter pelo menos 3 caracteres';
    } else {
      usernameValidationError = null;
    }
    notifyListeners();
  }

  void _validatePassword() {
    if (password.isEmpty && !isClicked) {
      passwordValidationError = null;
    } else if (password.isEmpty && isClicked) {
      passwordValidationError = 'Campo obrigatorio';
    } else if (password.length < 3) {
      passwordValidationError = 'A senha deve ter pelo menos 3 caracteres';
    } else {
      passwordValidationError = null;
    }
    notifyListeners();
  }

  void clear() {
    usernameController.clear();
    passwordController.clear();
    usernameValidationError = null;
    passwordValidationError = null;
    usernameAuthError = null;
    passwordAuthError = null;
    loginError = null;
    isClicked = false;
    isLoading = false;
    _lastUsernameText = usernameController.text;
    _lastPasswordText = passwordController.text;
  }

  @override
  void dispose() {
    usernameController.removeListener(_handleUsernameChanged);
    passwordController.removeListener(_handlePasswordChanged);
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
