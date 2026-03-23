import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lexii/core/theme/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _supabase = Supabase.instance.client;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  String? _userId;
  String? _conversationId;
  String _displayName = 'User';
  String? _avatarUrl;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initConversation() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        context.go('/auth/signup');
        return;
      }

      _userId = user.id;
      _displayName =
          (user.userMetadata?['full_name'] as String?) ??
          (user.userMetadata?['name'] as String?) ??
          user.email?.split('@').first ??
          'User';
      _avatarUrl = user.userMetadata?['avatar_url'] as String?;

      final profile = await _supabase
          .from('profiles')
          .select('avatar_url,full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null) {
        final profileName = profile['full_name'] as String?;
        final profileAvatar = profile['avatar_url'] as String?;
        if (profileName != null && profileName.trim().isNotEmpty) {
          _displayName = profileName;
        }
        if (profileAvatar != null && profileAvatar.trim().isNotEmpty) {
          _avatarUrl = profileAvatar;
        }
      }

      final existing = await _supabase
          .from('chat_conversations')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      String? conversationId = existing?['id'] as String?;

      if (conversationId == null || conversationId.isEmpty) {
        final created = await _supabase
            .from('chat_conversations')
            .insert({'user_id': user.id})
            .select('id')
            .single();
        conversationId = created['id'] as String?;
      }

      if (conversationId == null || conversationId.isEmpty) {
        throw Exception('Không tạo được cuộc trò chuyện');
      }

      _conversationId = conversationId;
      await _markAdminMessagesRead();

      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể kết nối hỗ trợ lúc này.';
      });
    }
  }

  Future<void> _markAdminMessagesRead() async {
    if (_conversationId == null || _userId == null) return;
    try {
      await _supabase.rpc(
        'mark_user_read',
        params: {'conv_id': _conversationId, 'reader_id': _userId},
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty ||
        _conversationId == null ||
        _userId == null ||
        _sending) {
      return;
    }

    setState(() => _sending = true);
    _inputController.clear();

    try {
      await _supabase.from('chat_messages').insert({
        'conversation_id': _conversationId,
        'sender_id': _userId,
        'sender_role': 'user',
        'content': text,
      });
      await _scrollToBottomAnimated();
    } catch (_) {
      if (!mounted) return;
      _inputController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không gửi được tin nhắn. Vui lòng thử lại.',
            style: GoogleFonts.lexend(color: Colors.white, fontSize: 13),
          ),
          backgroundColor: AppColors.red500,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _scrollToBottomAnimated() async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  String _formatTime(DateTime dateTime) {
    final h = dateTime.hour.toString().padLeft(2, '0');
    final m = dateTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateLabel(DateTime dateTime) {
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );
    final diff = normalizedNow.difference(normalizedDate).inDays;

    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    return '$day/$month/$year';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final chars = parts
        .where((e) => e.isNotEmpty)
        .map((e) => e[0])
        .take(2)
        .join();
    return chars.isEmpty ? 'U' : chars.toUpperCase();
  }

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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF8FAFC), Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, topPadding),
                Expanded(child: _buildBody()),
                _buildComposer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, topPadding + 12, 12, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hỗ trợ Lexii',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Phản hồi & Hỗ trợ',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
            CircleAvatar(radius: 17, backgroundImage: NetworkImage(_avatarUrl!))
          else
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: Text(
                _initials(_displayName),
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              'Đang kết nối...',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textSlate500,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppColors.textSlate600,
            ),
          ),
        ),
      );
    }

    if (_conversationId == null) {
      return const SizedBox.shrink();
    }

    final stream = _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', _conversationId!)
        .order('created_at', ascending: true);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Không tải được tin nhắn. Vui lòng thử lại.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.textSlate600,
                ),
              ),
            ),
          );
        }

        final rows = snapshot.data ?? const <Map<String, dynamic>>[];

        if (rows.length != _lastMessageCount) {
          _lastMessageCount = rows.length;
          unawaited(_markAdminMessagesRead());
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottomAnimated();
          });
        }

        if (rows.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(39),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Kết nối với đội ngũ hỗ trợ',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSlate800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gửi tin nhắn để được đội ngũ Lexii hỗ trợ nhanh chóng. Chúng tôi sẵn sàng giúp bạn 24/7.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: AppColors.textSlate500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final grouped = <String, List<Map<String, dynamic>>>{};
        final order = <String>[];

        for (final row in rows) {
          final createdAt =
              DateTime.tryParse('${row['created_at']}')?.toLocal() ??
              DateTime.now();
          final label = _formatDateLabel(createdAt);
          if (!grouped.containsKey(label)) {
            grouped[label] = <Map<String, dynamic>>[];
            order.add(label);
          }
          grouped[label]!.add(row);
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          itemCount: order.length,
          itemBuilder: (context, index) {
            final label = order[index];
            final messages = grouped[label] ?? const <Map<String, dynamic>>[];

            return Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.borderSlate200),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.lexend(
                          fontSize: 11,
                          color: AppColors.textSlate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.borderSlate200),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...messages.map((msg) => _buildMessageBubble(msg)),
                const SizedBox(height: 10),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> row) {
    final role = ('${row['sender_role'] ?? ''}').toLowerCase();
    final content = '${row['content'] ?? ''}';
    final isMe = role == 'user';
    final isSystem = role == 'system';
    final isRead = row['is_read'] == true;
    final createdAt =
        DateTime.tryParse('${row['created_at']}')?.toLocal() ?? DateTime.now();

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.borderSlate200),
            ),
            child: Text(
              content,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textSlate500,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.support_agent,
                size: 14,
                color: Colors.white,
              ),
            ),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isMe ? 14 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 14),
                ),
                border: isMe
                    ? null
                    : Border.all(color: AppColors.borderSlate200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: GoogleFonts.lexend(
                      fontSize: 13,
                      color: isMe ? Colors.white : AppColors.textSlate800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(createdAt),
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.78)
                              : AppColors.textSlate400,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderSlate200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSlate200),
              ),
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  color: AppColors.textSlate800,
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textSlate400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: (_sending || _conversationId == null)
                  ? null
                  : _sendMessage,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.slate200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.zero,
              ),
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
