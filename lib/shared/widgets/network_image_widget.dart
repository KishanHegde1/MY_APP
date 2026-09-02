import 'package:flutter/material.dart';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    required this.url,
    this.fit = BoxFit.cover,
    super.key,
  });
  final String url;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    fit: fit,
    errorBuilder: (_, _, _) => const ColoredBox(
      color: Colors.black12,
      child: Center(child: Icon(Icons.broken_image_outlined)),
    ),
  );
}
