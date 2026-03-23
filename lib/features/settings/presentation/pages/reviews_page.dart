import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

enum _ReviewTab { browse, write }

enum _SortBy { newest, oldest, likes }

class _ReviewItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating;
  final String content;
  final List<String> images;
  final DateTime createdAt;
  final int likesCount;
  final bool isLiked;

  const _ReviewItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.content,
    required this.images,
    required this.createdAt,
    required this.likesCount,
    required this.isLiked,
  });

  _ReviewItem copyWith({bool? isLiked, int? likesCount}) {
    return _ReviewItem(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      rating: rating,
      content: content,
      images: images,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class _ReviewsPageState extends State<ReviewsPage> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final _contentController = TextEditingController();

  static const _perPage = 10;
  static const _maxImages = 5;
  static const _maxChars = 500;

  _ReviewTab _tab = _ReviewTab.browse;
  _SortBy _sortBy = _SortBy.newest;
  int? _starFilter;

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _submitting = false;
  bool _submitted = false;

  String? _userId;

  final List<_ReviewItem> _reviews = [];
  final List<XFile> _pickedImages = [];
  final List<Uint8List> _pickedPreviewBytes = [];
  int _rating = 0;
  int _hoverRating = 0;
  static const bool _debugReviewProfiles = true;

  void _logDebug(String message) {
    if (!kDebugMode || !_debugReviewProfiles) return;
    debugPrint('[REVIEWS_DEBUG] $message');
  }

  void _applyStatusBarStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _applyStatusBarStyle();
    _initUserAndData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyStatusBarStyle();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndData() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _userId = user.id;
    }
    await _fetchReviews(reset: true);
  }

  Map<String, dynamic>? _extractProfile(dynamic raw) {
    Map<String, dynamic>? normalizeMap(dynamic value) {
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map((key, val) => MapEntry('$key', val));
      }
      return null;
    }

    final fromMap = normalizeMap(raw);
    if (fromMap != null) return fromMap;

    if (raw is List && raw.isNotEmpty) {
      final first = normalizeMap(raw.first);
      if (first != null) return first;
    }

    return null;
  }

  String? _readNonEmptyString(dynamic value) {
    if (value == null) return null;
    final text = '$value'.trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return null;
    return text;
  }

  String _resolveUserName({
    required String userId,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? row,
  }) {
    final name =
        _readNonEmptyString(profile?['full_name']) ??
        _readNonEmptyString(row?['user_name']) ??
        _readNonEmptyString(row?['userName']) ??
        _readNonEmptyString(row?['full_name']);
    if (name != null) return name;
    return userId.length >= 8 ? 'User ${userId.substring(0, 8)}' : 'Người dùng';
  }

  String? _resolveAvatarUrl({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? row,
  }) {
    final raw =
        _readNonEmptyString(profile?['avatar_url']) ??
        _readNonEmptyString(row?['user_avatar']) ??
        _readNonEmptyString(row?['userAvatar']) ??
        _readNonEmptyString(row?['avatar_url']);
    if (raw == null) return null;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }

    var path = raw;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('avatars/')) path = path.substring('avatars/'.length);
    if (path.isEmpty) return null;

    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<void> _fetchReviews({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _hasMore = true;
      });
    }

    try {
      final start = reset ? 0 : _reviews.length;
      final end = start + _perPage - 1;

      final response = await _supabase
          .from('reviews')
          .select('*,profiles:user_id(id,full_name,avatar_url)')
          .order('created_at', ascending: false)
          .range(start, end);

      final rows = (response as List).cast<Map<String, dynamic>>();
      _logDebug(
        'Fetched reviews count=${rows.length}, reset=$reset, range=$start..$end',
      );
      for (var i = 0; i < min(5, rows.length); i++) {
        final row = rows[i];
        _logDebug(
          'row[$i] id=${row['id']} user_id=${row['user_id']} profilesType=${row['profiles']?.runtimeType} '
          'user_name=${row['user_name']} avatar_url=${row['avatar_url']} user_avatar=${row['user_avatar']}',
        );
      }

      final userIds = rows.map((e) => '${e['user_id']}').toSet().toList();
      final Map<String, Map<String, dynamic>> profileByUserId =
          <String, Map<String, dynamic>>{};

      if (userIds.isNotEmpty) {
        try {
          final profileResponse = await _supabase
              .from('profiles')
              .select('id,full_name,avatar_url')
              .inFilter('id', userIds);

          final profileRows = (profileResponse as List)
              .cast<Map<String, dynamic>>();
          _logDebug(
            'Fetched profiles count=${profileRows.length} for userIds=${userIds.length}',
          );
          for (final p in profileRows) {
            final id = '${p['id']}';
            profileByUserId[id] = p;
          }
        } catch (_) {
          // Keep UI usable with join/user_id fallback if profile query fails.
          _logDebug('Profile query failed for reviews userIds.');
        }
      }

      Set<String> likedIds = <String>{};
      if (_userId != null) {
        final likesResponse = await _supabase
            .from('review_likes')
            .select('review_id')
            .eq('user_id', _userId!);
        final likesRows = (likesResponse as List).cast<Map<String, dynamic>>();
        likedIds = likesRows.map((e) => '${e['review_id']}').toSet();
      }

      final mapped = rows.map((row) {
        final userId = '${row['user_id']}';
        final profile =
            _extractProfile(row['profiles']) ?? profileByUserId[userId];
        final resolvedName = _resolveUserName(
          userId: userId,
          profile: profile,
          row: row,
        );
        final resolvedAvatar = _resolveAvatarUrl(profile: profile, row: row);
        return _ReviewItem(
          id: '${row['id']}',
          userId: userId,
          userName: resolvedName,
          userAvatar: resolvedAvatar,
          rating: (row['rating'] as num?)?.toInt() ?? 0,
          content: '${row['content'] ?? ''}',
          images: ((row['images'] as List?) ?? const [])
              .map((e) => '$e')
              .toList(),
          createdAt:
              DateTime.tryParse('${row['created_at']}')?.toLocal() ??
              DateTime.now(),
          likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
          isLiked: likedIds.contains('${row['id']}'),
        );
      }).toList();

      for (var i = 0; i < min(5, mapped.length); i++) {
        final item = mapped[i];
        _logDebug(
          'mapped[$i] id=${item.id} userId=${item.userId} userName="${item.userName}" avatar=${item.userAvatar}',
        );
      }

      setState(() {
        if (reset) {
          _reviews
            ..clear()
            ..addAll(mapped);
        } else {
          _reviews.addAll(mapped);
        }
        _hasMore = mapped.length == _perPage;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không tải được đánh giá.',
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.red500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetchReviews(reset: false);
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _pickedImages.length;
    if (remaining <= 0) return;

    final selected = await _picker.pickMultiImage(
      imageQuality: 85,
      limit: remaining,
    );
    if (selected.isEmpty) return;

    final previews = <Uint8List>[];
    for (final file in selected.take(remaining)) {
      previews.add(await file.readAsBytes());
    }

    setState(() {
      _pickedImages.addAll(selected.take(remaining));
      _pickedPreviewBytes.addAll(previews);
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0 ||
        _contentController.text.trim().length < 10 ||
        _userId == null ||
        _submitting) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final uploadedUrls = <String>[];
      for (final image in _pickedImages) {
        final bytes = await image.readAsBytes();
        final ext = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';
        final random = Random().nextInt(999999).toString().padLeft(6, '0');
        final fileName =
            '${_userId}/${DateTime.now().millisecondsSinceEpoch}-$random.$ext';

        await _supabase.storage
            .from('review-images')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: false),
            );

        final publicUrl = _supabase.storage
            .from('review-images')
            .getPublicUrl(fileName);
        uploadedUrls.add(publicUrl);
      }

      final inserted = await _supabase
          .from('reviews')
          .insert({
            'user_id': _userId,
            'rating': _rating,
            'content': _contentController.text.trim(),
            'images': uploadedUrls,
          })
          .select('*,profiles:user_id(id,full_name,avatar_url)')
          .single();

      Map<String, dynamic>? profile = _extractProfile(inserted['profiles']);
      if (profile == null && _userId != null) {
        try {
          profile = await _supabase
              .from('profiles')
              .select('id,full_name,avatar_url')
              .eq('id', _userId!)
              .maybeSingle();
        } catch (_) {
          // Ignore fallback fetch failure and continue with local user name.
        }
      }
      final item = _ReviewItem(
        id: '${inserted['id']}',
        userId: '${inserted['user_id']}',
        userName: _resolveUserName(
          userId: '${inserted['user_id']}',
          profile: profile,
          row: inserted,
        ),
        userAvatar: _resolveAvatarUrl(profile: profile, row: inserted),
        rating: (inserted['rating'] as num?)?.toInt() ?? _rating,
        content: '${inserted['content'] ?? ''}',
        images: ((inserted['images'] as List?) ?? const [])
            .map((e) => '$e')
            .toList(),
        createdAt:
            DateTime.tryParse('${inserted['created_at']}')?.toLocal() ??
            DateTime.now(),
        likesCount: (inserted['likes_count'] as num?)?.toInt() ?? 0,
        isLiked: false,
      );

      setState(() {
        _reviews.insert(0, item);
        _submitted = true;
      });

      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      setState(() {
        _submitted = false;
        _rating = 0;
        _hoverRating = 0;
        _pickedImages.clear();
        _pickedPreviewBytes.clear();
        _contentController.clear();
        _tab = _ReviewTab.browse;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không gửi được đánh giá. Vui lòng thử lại.',
              style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.red500,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _toggleLike(String reviewId) async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng đăng nhập để thích đánh giá.',
            style: GoogleFonts.lexend(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index < 0) return;

    final item = _reviews[index];
    final nextLiked = !item.isLiked;
    final nextCount = item.likesCount + (nextLiked ? 1 : -1);

    setState(() {
      _reviews[index] = item.copyWith(
        isLiked: nextLiked,
        likesCount: max(0, nextCount),
      );
    });

    try {
      if (nextLiked) {
        await _supabase.from('review_likes').insert({
          'review_id': reviewId,
          'user_id': _userId,
        });
      } else {
        await _supabase
            .from('review_likes')
            .delete()
            .eq('review_id', reviewId)
            .eq('user_id', _userId!);
      }
    } catch (_) {
      setState(() {
        _reviews[index] = item;
      });
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 30) return '${diff.inDays} ngày trước';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  List<_ReviewItem> get _filteredReviews {
    final list = _reviews
        .where((r) => _starFilter == null || r.rating == _starFilter)
        .toList();
    list.sort((a, b) {
      switch (_sortBy) {
        case _SortBy.newest:
          return b.createdAt.compareTo(a.createdAt);
        case _SortBy.oldest:
          return a.createdAt.compareTo(b.createdAt);
        case _SortBy.likes:
          return b.likesCount.compareTo(a.likesCount);
      }
    });
    return list;
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (s, r) => s + r.rating);
    return sum / _reviews.length;
  }

  int _ratingCount(int star) => _reviews.where((r) => r.rating == star).length;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Container(
            color: AppColors.backgroundLight,
            child: Column(
              children: [
                _buildHeader(topPadding),
                Expanded(
                  child: _loading
                      ? _buildLoading()
                      : _tab == _ReviewTab.browse
                      ? _buildBrowseTab()
                      : _buildWriteTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đánh giá ứng dụng',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'Chia sẻ trải nghiệm của bạn với Lexii',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: const Color(0xFFCCFBF1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            'Đang tải đánh giá...',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SwitchTabButton(
              active: _tab == _ReviewTab.browse,
              label: 'Xem đánh giá',
              onTap: () => setState(() => _tab = _ReviewTab.browse),
            ),
          ),
          Expanded(
            child: _SwitchTabButton(
              active: _tab == _ReviewTab.write,
              label: 'Viết đánh giá',
              onTap: () {
                if (_userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Vui lòng đăng nhập để viết đánh giá.',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                setState(() => _tab = _ReviewTab.write);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowseTab() {
    final items = _filteredReviews;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTabSwitcher(),
        _buildStatsCard(),
        _buildFilterRow(),
        if (items.isEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Icon(
                    Icons.star_border,
                    color: AppColors.textSlate400,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chưa có đánh giá nào',
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSlate800,
                  ),
                ),
              ],
            ),
          )
        else ...[
          const SizedBox(height: 6),
          ...items.map(
            (item) => _ReviewCard(
              item: item,
              timeAgo: _timeAgo(item.createdAt),
              onLike: () => _toggleLike(item.id),
              onImageTap: (url) => _openImage(url),
            ),
          ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: OutlinedButton(
                onPressed: _loadingMore ? null : _loadMore,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.borderSlate200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Xem thêm đánh giá',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: AppColors.textSlate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Column(
              children: [
                Text(
                  _avgRating.toStringAsFixed(1),
                  style: GoogleFonts.lexend(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final active = i < _avgRating.round();
                    return Icon(
                      Icons.star,
                      size: 13,
                      color: active
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF99F6E4),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_reviews.length} đánh giá',
                  style: GoogleFonts.lexend(
                    fontSize: 11,
                    color: const Color(0xFFCCFBF1),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 62, color: const Color(0x3342d6c5)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = _ratingCount(star);
                final double pct = _reviews.isEmpty
                    ? 0.0
                    : (count / _reviews.length);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: const Color(0xFFCCFBF1),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: pct,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFF59E0B),
                            ),
                            backgroundColor: const Color(0x3342d6c5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 16,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.lexend(
                            fontSize: 11,
                            color: const Color(0xFFCCFBF1),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          PopupMenuButton<_SortBy>(
            initialValue: _sortBy,
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _SortBy.newest,
                child: Text('Mới nhất'),
              ),
              const PopupMenuItem(
                value: _SortBy.oldest,
                child: Text('Cũ nhất'),
              ),
              const PopupMenuItem(
                value: _SortBy.likes,
                child: Text('Nhiều lượt thích'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSlate200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortBy == _SortBy.newest
                        ? 'Mới nhất'
                        : _sortBy == _SortBy.oldest
                        ? 'Cũ nhất'
                        : 'Nhiều lượt thích',
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AppColors.textSlate500,
                  ),
                ],
              ),
            ),
          ),
          ...<int?>[null, 5, 4, 3, 2, 1].map((f) {
            final active = _starFilter == f;
            return InkWell(
              onTap: () => setState(() => _starFilter = f),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? AppColors.primary
                        : AppColors.borderSlate200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f == null ? 'Tất cả' : '$f',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: active ? Colors.white : AppColors.textSlate600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (f != null) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.star,
                        size: 13,
                        color: active
                            ? const Color(0xFFF59E0B)
                            : AppColors.textSlate400,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWriteTab() {
    final content = _contentController.text;
    final valid = _rating > 0 && content.trim().length >= 10;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildTabSwitcher(),
        if (_submitted)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(39),
                  ),
                  child: const Icon(
                    Icons.star,
                    size: 38,
                    color: AppColors.green600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cảm ơn bạn!',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đánh giá của bạn đã được gửi thành công.',
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate500,
                  ),
                ),
              ],
            ),
          )
        else ...[
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá của bạn',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bạn hài lòng với ứng dụng không?',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.textSlate400,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...List.generate(5, (i) {
                      final star = i + 1;
                      final active =
                          star <= (_hoverRating == 0 ? _rating : _hoverRating);
                      return MouseRegion(
                        onEnter: (_) => setState(() => _hoverRating = star),
                        onExit: (_) => setState(() => _hoverRating = 0),
                        child: InkWell(
                          onTap: () => setState(() => _rating = star),
                          borderRadius: BorderRadius.circular(999),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.star,
                              size: 34,
                              color: active
                                  ? const Color(0xFFFBBF24)
                                  : AppColors.slate200,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      _rating == 0
                          ? ''
                          : _rating == 1
                          ? 'Rất không hài lòng'
                          : _rating == 2
                          ? 'Không hài lòng'
                          : _rating == 3
                          ? 'Bình thường'
                          : _rating == 4
                          ? 'Hài lòng'
                          : 'Rất hài lòng',
                      style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSlate600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nội dung đánh giá',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chia sẻ trải nghiệm của bạn (tối thiểu 10 ký tự)',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.textSlate400,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 8,
                  onChanged: (v) {
                    if (v.length > _maxChars) {
                      _contentController.text = v.substring(0, _maxChars);
                      _contentController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _contentController.text.length),
                      );
                    }
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Ví dụ: Ứng dụng rất hữu ích, giúp mình cải thiện điểm TOEIC rõ rệt...',
                    hintStyle: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderSlate200,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderSlate200,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      content.trim().length < 10
                          ? 'Cần thêm ${10 - content.trim().length} ký tự'
                          : 'Đủ điều kiện gửi',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: content.trim().length < 10
                            ? AppColors.red500
                            : AppColors.green600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${content.length}/$_maxChars',
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hình ảnh đính kèm',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSlate800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tải lên tối đa $_maxImages hình (${_pickedImages.length}/$_maxImages)',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.textSlate400,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 94,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._pickedImages.asMap().entries.map((entry) {
                        final i = entry.key;
                        return Container(
                          width: 92,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: MemoryImage(_pickedPreviewBytes[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: InkWell(
                                onTap: () => setState(() {
                                  _pickedImages.removeAt(i);
                                  _pickedPreviewBytes.removeAt(i);
                                }),
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      if (_pickedImages.length < _maxImages)
                        InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.borderSlate200,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: AppColors.textSlate400,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Thêm ảnh',
                                  style: GoogleFonts.lexend(
                                    fontSize: 11,
                                    color: AppColors.textSlate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (valid && !_submitting) ? _submitReview : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.slate200,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.lexend(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Đang gửi đánh giá...' : 'Gửi đánh giá',
                    ),
                  ),
                ),
                if (!valid)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Vui lòng chọn số sao và nhập ít nhất 10 ký tự để gửi đánh giá.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openImage(String url) async {
    await showDialog<void>(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _SwitchTabButton extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _SwitchTabButton({
    required this.active,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.textSlate500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final _ReviewItem item;
  final String timeAgo;
  final VoidCallback onLike;
  final ValueChanged<String> onImageTap;

  const _ReviewCard({
    required this.item,
    required this.timeAgo,
    required this.onLike,
    required this.onImageTap,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    const longContent = 200;
    final isLong = widget.item.content.length > longContent;
    final text = !expanded && isLong
        ? '${widget.item.content.substring(0, longContent)}...'
        : widget.item.content;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSlate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal100,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    widget.item.userAvatar != null &&
                        widget.item.userAvatar!.isNotEmpty
                    ? Image.network(
                        widget.item.userAvatar!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          if (kDebugMode) {
                            debugPrint(
                              '[REVIEWS_DEBUG] avatar load failed url=${widget.item.userAvatar} error=$error',
                            );
                          }
                          return const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          );
                        },
                      )
                    : const Icon(Icons.person, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.userName,
                            style: GoogleFonts.lexend(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSlate800,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(5, (i) {
                            final active = i < widget.item.rating;
                            return Icon(
                              Icons.star,
                              size: 14,
                              color: active
                                  ? const Color(0xFFF59E0B)
                                  : AppColors.slate200,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.timeAgo,
                      style: GoogleFonts.lexend(
                        fontSize: 11,
                        color: AppColors.textSlate400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textSlate600,
              height: 1.35,
            ),
          ),
          if (isLong)
            InkWell(
              onTap: () => setState(() => expanded = !expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  expanded ? 'Thu gọn' : 'Xem thêm',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (widget.item.images.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, i) {
                    final url = widget.item.images[i];
                    return InkWell(
                      onTap: () => widget.onImageTap(url),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 82,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.slate100,
                        ),
                        child: Image.network(url, fit: BoxFit.cover),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: widget.item.images.length,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.borderSlate100),
          const SizedBox(height: 8),
          InkWell(
            onTap: widget.onLike,
            child: Row(
              children: [
                Icon(
                  Icons.thumb_up_alt_outlined,
                  size: 15,
                  color: widget.item.isLiked
                      ? AppColors.primary
                      : AppColors.textSlate400,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.item.likesCount > 0 ? '${widget.item.likesCount}' : '',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: widget.item.isLiked
                        ? AppColors.primary
                        : AppColors.textSlate400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
