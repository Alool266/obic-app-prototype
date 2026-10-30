// Made by Dr Ali
// Network photo that stays on disk after the first successful load.

import 'dart:io';

import 'package:flutter/material.dart';

import '../core/media_disk_cache.dart';
import '../core/media_url.dart';

class ObicCachedImage extends StatefulWidget {
  const ObicCachedImage(
    this.url, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.low,
    this.gaplessPlayback = false,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String url;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final bool gaplessPlayback;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  State<ObicCachedImage> createState() => _ObicCachedImageState();
}

class _ObicCachedImageState extends State<ObicCachedImage> {
  File? _file;
  bool _failed = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ObicCachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _load();
  }

  Future<void> _load() async {
    final url = resolveMediaUrl(widget.url);
    if (url.isEmpty) {
      if (mounted) {
        setState(() {
          _file = null;
          _failed = true;
          _loading = false;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    final file = await MediaDiskCache.instance.resolve(url);
    if (!mounted || resolveMediaUrl(widget.url) != url) return;
    setState(() {
      _file = file;
      _failed = file == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    if (file != null) {
      return Image.file(
        file,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        filterQuality: widget.filterQuality,
        gaplessPlayback: widget.gaplessPlayback,
        errorBuilder: widget.errorBuilder,
      );
    }
    if (_loading) {
      final placeholder = SizedBox(width: widget.width, height: widget.height);
      final builder = widget.loadingBuilder;
      if (builder != null) {
        return builder(context, placeholder, null);
      }
      return placeholder;
    }
    final err = widget.errorBuilder;
    if (err != null && _failed) {
      return err(context, StateError('image unavailable'), null);
    }
    return SizedBox(width: widget.width, height: widget.height);
  }
}
