import 'package:flutter/material.dart';
import 'package:ikwimpay/providers/auth_provider.dart';
import 'package:ikwimpay/scr/homescreen.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true; // For password visibility toggle
  bool _checkedLogin = false;
  bool _isCheckingLogin = true; // Start with checking login

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Start login check immediately in initState
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isCheckingLogin = true; // Indicate we're checking login
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.checkLoginStatus();

    setState(() {
      _isCheckingLogin = false; // Check complete
    });

    // Navigate if logged in
    if (authProvider.isLoggedIn && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the back button
        title: const Text(
          'ITEC LTD  V 1.2',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              'assets/images/ikwim_tr.png',
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            ),
          ),
        ],
        backgroundColor: const Color(0xFF870813),
      ),
      body: _isCheckingLogin
          ? _buildLoadingScreen() // Show loading during check
          : _buildLoginForm(authProvider), // Show login form after check fails
    );
  }

  // Loading spinner screen
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Color(0xFF870813)),
          SizedBox(height: 20),
          Text('Checking login status...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Login form - extracted from the original build method
  Widget _buildLoginForm(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontWeight: FontWeight.w300),
                      decoration: InputDecoration(
                        labelText: 'Phone',
                        hintText: 'Phone',
                        hintStyle: const TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        errorStyle: const TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 16),
                        prefixIcon: const Icon(
                          Icons.email,
                          weight: 300,
                          size: 20,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone';
                        }
                        return null;
                      },
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 20),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Password',
                        hintStyle: const TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        errorStyle: const TextStyle(
                            fontWeight: FontWeight.w300, fontSize: 16),
                        prefixIcon: const Icon(
                          Icons.lock,
                          size: 20,
                          weight: 300,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 20,
                            weight: 300,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const Divider(color: Colors.white70),
                    const SizedBox(height: 5),
                    if (authProvider.errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage,
                                  style:
                                      const TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                FocusScope.of(context).unfocus();
                                if (_formKey.currentState!.validate()) {
                                  bool success = await authProvider.login(
                                    _emailController.text,
                                    _passwordController.text,
                                  );

                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Login successful!'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    Future.delayed(const Duration(seconds: 1),
                                        () {
                                      if (mounted) {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeScreen(),
                                          ),
                                        );
                                      }
                                    });
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF870813),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'LOGIN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
