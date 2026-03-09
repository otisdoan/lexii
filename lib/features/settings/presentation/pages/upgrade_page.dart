import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  // 0 = 6 tháng, 1 = Trọn đời, 2 = Hàng năm
  int _selectedPlan = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate100,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Nâng cấp',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section 1: Feature Banner
                    _FeatureBanner(),
                    const SizedBox(height: 20),
                    // Section 2: Subscription Plans
                    _PlanSelector(
                      selected: _selectedPlan,
                      onSelect: (i) => setState(() => _selectedPlan = i),
                    ),
                    const SizedBox(height: 20),
                    // CTA Button
                    _UpgradeButton(planIndex: _selectedPlan),
                    const SizedBox(height: 16),
                    // Section 3: Restore & Skip
                    _RestoreSkipSection(onSkip: () => context.pop()),
                    const SizedBox(height: 20),
                    // Section 4: Account Status
                    _AccountStatusSection(),
                    const SizedBox(height: 20),
                    // Section 5: Feature Comparison
                    _FeatureComparisonTable(),
                    const SizedBox(height: 20),
                    // Section 6: User Reviews
                    _UserReviewsSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feature Banner ───────────────────────────────────────────────────────────

class _FeatureBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 52,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '30 đề thi cấu trúc MỚI NHẤT',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textSlate800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '12.000 câu hỏi TOEIC đầy đủ đáp án và giải thích chi tiết',
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate500,
            ),
          ),
          const SizedBox(height: 16),
          // Dots indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _dot(true),
              const SizedBox(width: 6),
              _dot(false),
              const SizedBox(width: 6),
              _dot(false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? AppColors.primary
            : AppColors.primary.withValues(alpha: 0.3),
      ),
    );
  }
}

// ─── Plan Selector ────────────────────────────────────────────────────────────

class _PlanSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _PlanSelector({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          // 6 tháng
          _PlanCard(
            title: '6 tháng',
            badge: '10% OFF',
            badgeColor: AppColors.primary,
            price: null,
            priceLabel: null,
            isHighlighted: false,
            isSelected: selected == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(width: 12),
          // Trọn đời (highlighted)
          _PlanCard(
            title: 'Trọn đời',
            badge: 'Best Choice',
            badgeColor: AppColors.primary,
            price: '1.499.000 đ',
            originalPrice: '2.998.000 đ',
            discount: 'GIẢM 50%',
            isHighlighted: true,
            isSelected: selected == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(width: 12),
          // Hàng năm
          _PlanCard(
            title: 'Hàng năm',
            badge: null,
            badgeColor: AppColors.primary,
            price: '599.000 đ',
            priceLabel: 'Chỉ 49.000 đ/tháng',
            isHighlighted: false,
            isSelected: selected == 2,
            onTap: () => onSelect(2),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String? badge;
  final Color badgeColor;
  final String? price;
  final String? originalPrice;
  final String? discount;
  final String? priceLabel;
  final bool isHighlighted;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.isHighlighted,
    required this.isSelected,
    required this.onTap,
    this.price,
    this.originalPrice,
    this.discount,
    this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final double cardWidth = isHighlighted ? 200 : 140;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: cardWidth,
        padding: EdgeInsets.all(isHighlighted ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isHighlighted ? 16 : 12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSlate200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (badge != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    price!,
                    style: GoogleFonts.lexend(
                      fontSize: isHighlighted ? 20 : 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (originalPrice != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    originalPrice!,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      color: AppColors.textSlate400,
                      decoration: TextDecoration.lineThrough,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (discount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    discount!,
                    style: GoogleFonts.lexend(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.orange500,
                    ),
                  ),
                ],
                if (priceLabel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    priceLabel!,
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ],
              ],
            ),
            // "Best Choice" top badge for highlighted
            if (isHighlighted)
              Positioned(
                top: -28,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Best Choice',
                      style: GoogleFonts.lexend(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Upgrade Button ───────────────────────────────────────────────────────────

class _UpgradeButton extends StatelessWidget {
  final int planIndex;

  const _UpgradeButton({required this.planIndex});

  String get _buttonLabel {
    switch (planIndex) {
      case 0:
        return 'Nâng cấp 6 tháng';
      case 2:
        return 'Nâng cấp hàng năm';
      default:
        return 'Nâng cấp trọn đời';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tính năng đang phát triển',
                style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
              ),
              backgroundColor: AppColors.primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: Text(
          _buttonLabel,
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Restore & Skip ───────────────────────────────────────────────────────────

class _RestoreSkipSection extends StatelessWidget {
  final VoidCallback onSkip;

  const _RestoreSkipSection({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tính năng đang phát triển',
                  style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
                ),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Text(
            'Khôi phục thanh toán',
            style: GoogleFonts.lexend(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bạn có thể trải nghiệm một số phần miễn phí\nmà không cần nâng cấp.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: AppColors.textSlate400,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onSkip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bỏ qua và tiếp tục ',
                style: GoogleFonts.lexend(
                  color: AppColors.orange500,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.orange500, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Account Status Section ───────────────────────────────────────────────────

class _AccountStatusSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate600,
                    ),
                    children: const [
                      TextSpan(text: 'Tài khoản '),
                      TextSpan(
                        text: 'Phạm Thùy Trang',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: ' vừa nâng cấp'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: ['9', '9', '5', '7']
                .map((d) => _ScoreBox(digit: d))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String digit;

  const _ScoreBox({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSlate200),
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ─── Feature Comparison Table ─────────────────────────────────────────────────

class _FeatureComparisonTable extends StatelessWidget {
  static const _rows = [
    _ComparisonRow('Luyện tập part 1,2,5', true, true),
    _ComparisonRow('Học lý thuyết', true, true),
    _ComparisonRow('Luyện tập FULL 7 dạng bài', false, true),
    _ComparisonRow('Sử dụng ngoại tuyến', false, true),
    _ComparisonRow('Loại bỏ quảng cáo', false, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header row
            Container(
              color: AppColors.slate50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Tính năng',
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSlate500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        'Miễn phí',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSlate500,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Center(
                      child: Text(
                        'Premium',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ..._rows.map((r) => _buildRow(r)),
            // Last row: exam count
            _buildCountRow('Mở khóa đề thi thử', '4', '30'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(_ComparisonRow row) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderSlate100),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  row.feature,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: Icon(
                    row.free
                        ? Icons.check_circle
                        : Icons.lock_outline,
                    size: 20,
                    color:
                        row.free ? AppColors.green600 : AppColors.textSlate300,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCountRow(String feature, String freeCount, String premiumCount) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderSlate100),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  feature,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSlate600,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: Text(
                    freeCount,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Center(
                  child: Text(
                    premiumCount,
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow {
  final String feature;
  final bool free;
  final bool premium;

  const _ComparisonRow(this.feature, this.free, this.premium);
}

// ─── User Reviews Section ─────────────────────────────────────────────────────

class _UserReviewsSection extends StatelessWidget {
  static const _reviews = [
    _Review(
      name: 'Chàng Thơ',
      stars: 5,
      text:
          '"App cực kỳ chất lượng, đề thi sát với thực tế. Mình đã đạt được 850+ nhờ luyện tập đều đặn trên đây. Rất đáng đồng tiền bát gạo!"',
    ),
    _Review(
      name: 'Minh Trí',
      stars: 5,
      text:
          '"Giải thích chi tiết từng câu hỏi, rất dễ hiểu. Chỉ sau 2 tháng tôi đã tăng thêm 150 điểm!"',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phản hồi của người dùng',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textSlate800,
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReviewCard(review: r),
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final _Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.name[0],
                  style: GoogleFonts.lexend(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.name,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  Row(
                    children: List.generate(
                      review.stars,
                      (_) => const Icon(Icons.star,
                          size: 14, color: AppColors.yellow500),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.text,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textSlate600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _Review {
  final String name;
  final int stars;
  final String text;

  const _Review({required this.name, required this.stars, required this.text});
}
