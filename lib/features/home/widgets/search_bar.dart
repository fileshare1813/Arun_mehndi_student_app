import 'dart:ui';
import 'package:flutter/material.dart';

class HomeSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final String query;

  const HomeSearchBar({
    super.key,
    required this.onChanged,
    required this.onClear,
    required this.query,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    // Sync text controller with external query
    if (widget.query.isNotEmpty &&
        _textController.text != widget.query) {
      _textController.text = widget.query;
    }
  }

  @override
  void didUpdateWidget(covariant HomeSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Agar bahar se clear hua (query empty ho gayi)
    if (widget.query.isEmpty && _textController.text.isNotEmpty) {
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _textController.clear();
    _focusNode.unfocus();
    widget.onClear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1 + (_animation.value * 0.015),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _animation.value > 0.5
                          ? Colors.red.withOpacity(0.3)
                          : Colors.grey.shade200,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.05 + _animation.value * 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    onChanged: widget.onChanged,
                    decoration: InputDecoration(
                      hintText: "Courses, categories, instructors...",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),

                      // ── Prefix: Search Icon ───────────────
                      prefixIcon: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.search,
                          color: _animation.value > 0.5
                              ? Colors.red
                              : Colors.grey.shade500,
                          size: 22,
                        ),
                      ),

                      // ── Suffix: Clear Button ──────────────
                      suffixIcon: widget.query.isNotEmpty
                          ? GestureDetector(
                        onTap: _clearSearch,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.black54,
                            size: 16,
                          ),
                        ),
                      )
                          : null,

                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}