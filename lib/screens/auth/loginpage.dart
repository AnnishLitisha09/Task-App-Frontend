import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  // Matches the parameter name used in your RootWrapper
  final VoidCallback onLoginSuccess;
  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isGoogleSignInLoading = false;
  final _authService = AuthService();

  // --- Professional Minimalist Palette ---
  final Color primaryColor = const Color(0xFF2D62ED);
  final Color textHeading = const Color(0xFF1A1C1E);
  final Color textBody = const Color(0xFF42474E);
  final Color inputFill = const Color(0xFFF8FAFC);
  final Color inputBorder = const Color(0xFFE2E8F0);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Inside _LoginPageState class

  Future<void> _handleLogin() async {
    debugPrint('--- Login Started ---');
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    setState(() => _isGoogleSignInLoading = true);

    try {
      debugPrint('Attempting login with: $email');
      final result = await _authService.login(email, password);
      debugPrint('Login API response received: $result');

      final prefs = await SharedPreferences.getInstance();

      // Robust parsing
      final user = result['user'] is Map ? result['user'] : result;
      final userEmail = user['email'] ?? email;
      final role = (user['role'] ?? 'student').toString();
      final name = (user['name'] ?? '').toString();

      String category = role.toUpperCase();
      String scope = 'none';

      // Parse all_roles into a comma separated string to store locally
      String allRolesSaved = '';
      if (user['all_roles'] != null && user['all_roles'] is List) {
        allRolesSaved = (user['all_roles'] as List)
            .map((e) => e.toString().trim())
            .join(',');
      }

      String scopeDetailsSaved = user['scope_details']?.toString() ?? 'none';

      if (role == 'role-user') {
        category = (user['specific_role'] ?? 'User').toString();
        // Map scope_details to internal scope values
        String rawScope = scopeDetailsSaved.toLowerCase();
        if (rawScope.contains('department')) {
          scope = 'department';
        } else if (rawScope.contains('institution'))
          scope = 'institution';
        else if (rawScope.contains('infrastructure'))
          scope = 'infrastructure';
        else
          scope = rawScope;
      }

      final userId =
          int.tryParse(
            user['id']?.toString() ?? user['user_id']?.toString() ?? '0',
          ) ??
          0;

      await _saveUserSession(
        prefs,
        userEmail,
        role,
        category,
        userId: userId,
        scope: scope,
        name: name,
        token: result['token']?.toString(),
        allRoles: allRolesSaved,
        scopeDetails: scopeDetailsSaved,
      );
      debugPrint('Login success and session saved');
    } catch (e) {
      debugPrint('Login Error: $e');
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInLoading = false);
      }
    }
  }

  // Helper to keep code clean
  Future<void> _saveUserSession(
    SharedPreferences prefs,
    String email,
    String role,
    String category, {
    int userId = 0,
    String scope = 'none',
    String name = '',
    String? token,
    String allRoles = '',
    String scopeDetails = 'none',
  }) async {
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', userId);
    await prefs.setString('userEmail', email);
    await prefs.setString('userRole', role); // Primary role for MainWrapper
    await prefs.setString(
      'userTitle',
      category,
    ); // Visual title (HOD/Principal)
    await prefs.setString('userScope', scope); // Filtering logic (Dept/Inst)

    if (allRoles.isNotEmpty) {
      await prefs.setString('allRoles', allRoles);
    }
    await prefs.setString('scopeDetails', scopeDetails);

    if (name.isNotEmpty) {
      await prefs.setString('userName', name);
    }
    if (token != null) {
      await prefs.setString('authToken', token);
    }

    widget.onLoginSuccess();
  }

  Future<void> _handleGoogleSignIn() async {
    debugPrint('--- Google Sign-In Started ---');
    setState(() => _isGoogleSignInLoading = true);

    try {
      final result = await _authService.signInWithGoogle();
      debugPrint('Google Sign-In result: $result');

      if (result == null) {
        debugPrint('Google Sign-In canceled by user');
        if (mounted) setState(() => _isGoogleSignInLoading = false);
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Robust parsing
      final user = result['user'] is Map ? result['user'] : result;
      final email = (user['email'] ?? '').toString();
      final role = (user['role'] ?? 'student').toString();
      final name = (user['name'] ?? '').toString();

      String category = role.toUpperCase();
      String scope = 'none';

      // Parse all_roles into a comma separated string to store locally
      String allRolesSaved = '';
      if (user['all_roles'] != null && user['all_roles'] is List) {
        allRolesSaved = (user['all_roles'] as List)
            .map((e) => e.toString().trim())
            .join(',');
      }

      String scopeDetailsSaved = user['scope_details']?.toString() ?? 'none';

      if (role == 'role-user') {
        category = (user['specific_role'] ?? 'User').toString();
        // Map scope_details to internal scope values
        String rawScope = scopeDetailsSaved.toLowerCase();
        if (rawScope.contains('department')) {
          scope = 'department';
        } else if (rawScope.contains('institution'))
          scope = 'institution';
        else if (rawScope.contains('infrastructure'))
          scope = 'infrastructure';
        else
          scope = rawScope;
      }

      final userId =
          int.tryParse(
            user['id']?.toString() ?? user['user_id']?.toString() ?? '0',
          ) ??
          0;

      await _saveUserSession(
        prefs,
        email,
        role,
        category,
        userId: userId,
        scope: scope,
        name: name,
        token: result['token']?.toString(),
        allRoles: allRolesSaved,
        scopeDetails: scopeDetailsSaved,
      );
      debugPrint('Google Sign-In success and session saved');
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      _showError('Google Sign-In failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isGoogleSignInLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    color: textHeading,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your credentials to access your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textBody, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 48),
                _buildInputLabel('EMAIL ADDRESS'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _emailController,
                  hint: 'student@gmail.com',
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 24),
                _buildInputLabel('PASSWORD'),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: textBody.withOpacity(0.6),
                      size: 20,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _buildLoginButton(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildGoogleSignInButton(),
                const SizedBox(height: 40),
                _buildFooter(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildInputLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: textHeading.withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: textHeading, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: textBody.withOpacity(0.3),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: primaryColor.withOpacity(0.7),
            size: 20,
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: inputFill,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 20,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isGoogleSignInLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isGoogleSignInLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.bolt_rounded, color: primaryColor, size: 42),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("New here?", style: TextStyle(color: textBody)),
        TextButton(
          onPressed: () {},
          child: Text(
            'Create Account',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: inputBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: textBody.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: inputBorder)),
      ],
    );
  }

  Widget _buildGoogleSignInButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isGoogleSignInLoading ? null : _handleGoogleSignIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: textHeading,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: inputBorder, width: 1.5),
          ),
        ),
        child: _isGoogleSignInLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(
                    'https://cdn1.iconfinder.com/data/icons/google_jfk_icons_by_veresane/128/google.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: Text(
                      'Sign in with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
