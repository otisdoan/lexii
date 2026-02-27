import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Mascot
                    _buildMascotSection(),
                    const SizedBox(height: 32),
                    // Form
                    _buildForm(),
                    const SizedBox(height: 32),
                    // Social login
                    _buildSocialLogin(),
                    const SizedBox(height: 32),
                    // Login link
                    _buildLoginLink(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.8),
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.pop(),
              borderRadius: BorderRadius.circular(9999),
              child: Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textSlate900,
                ),
              ),
            ),
          ),
          // Title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 48),
              child: Text(
                'Đăng ký',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSlate900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotSection() {
    return Column(
      children: [
        // Avatar
        Stack(
          alignment: Alignment.center,
          children: [
            // Decorative blur
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Tạo tài khoản',
          style: GoogleFonts.lexend(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lexii - Luyện thi TOEIC tốt nhất',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSlate500,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name
          _buildInputField(
            controller: _nameController,
            hint: 'Họ và tên *',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          // Email
          _buildInputField(
            controller: _emailController,
            hint: 'Email *',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          // Phone
          _buildInputField(
            controller: _phoneController,
            hint: 'Số điện thoại',
            icon: Icons.phone_iphone,
            keyboardType: TextInputType.phone,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          // Password
          _buildPasswordField(
            controller: _passwordController,
            hint: 'Mật khẩu *',
            icon: Icons.lock_outline,
            obscure: _obscurePassword,
            onToggle: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          const SizedBox(height: 16),
          // Confirm password
          _buildPasswordField(
            controller: _confirmPasswordController,
            hint: 'Nhập lại mật khẩu *',
            icon: Icons.lock_reset,
            obscure: _obscureConfirmPassword,
            onToggle: () {
              setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
          ),
          const SizedBox(height: 24),
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _onSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                'Đăng ký',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dấu * là trường bắt buộc điền thông tin',
            style: GoogleFonts.lexend(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.orange500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.lexend(
          fontSize: 16,
          color: AppColors.textSlate900,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lexend(
            fontSize: 16,
            color: AppColors.textSlate400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.lexend(
          fontSize: 16,
          color: AppColors.textSlate900,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.lexend(
            fontSize: 16,
            color: AppColors.textSlate400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSlate400,
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: AppColors.borderSlate200)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'hoặc',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSlate400,
                ),
              ),
            ),
            const Expanded(child: Divider(color: AppColors.borderSlate200)),
          ],
        ),
        const SizedBox(height: 24),
        // Google button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _onGoogleSignIn,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSlate600,
              side: const BorderSide(color: AppColors.borderSlate200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google icon (simplified)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CustomPaint(painter: _GoogleLogoPainter()),
                ),
                const SizedBox(width: 12),
                Text(
                  'Đăng nhập bằng Google',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: GoogleFonts.lexend(
            fontSize: 14,
            color: AppColors.textSlate500,
          ),
        ),
        GestureDetector(
          onTap: () {
            // TODO: Navigate to login
          },
          child: Text(
            'Đăng nhập ngay',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  void _onSignUp() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: Implement sign up with Supabase
      context.go('/home');
    }
  }

  void _onGoogleSignIn() {
    // TODO: Implement Google sign in with Supabase
    context.go('/home');
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -0.5,
      1.2,
      true,
      bluePaint,
    );

    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      0.7,
      1.2,
      true,
      greenPaint,
    );

    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      1.9,
      1.2,
      true,
      yellowPaint,
    );

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromLTWH(0, 0, w, h),
      -1.8,
      1.3,
      true,
      redPaint,
    );

    // White center
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.32, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
