import 'dart:ui';
import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Usamos el color de superficie del tema
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Fondo base sólido
          Positioned.fill(
            child: Container(color: colorScheme.surface),
          ),

          // MESH GRADIENTS (Consumiendo del Theme)

          // Mancha Principal (Primary)
          Positioned(
            top: -150,
            right: -100,
            child: _BlurBlob(
              color: colorScheme.primary.withOpacity(isDark ? 0.15 : 0.10),
              width: 600,
            ),
          ),

          // Mancha de Acento / Error (Dynamic)
          Positioned(
            bottom: -100,
            left: -100,
            child: _BlurBlob(
              color: isDark
                  ? colorScheme.secondary.withOpacity(0.08)
                  : colorScheme.error.withOpacity(0.06),
              width: 500,
            ),
          ),

          // Mancha de profundidad para modo oscuro
          if (isDark)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: -150,
              child: _BlurBlob(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                width: 450,
              ),
            ),

          // Capa de desenfoque (Efecto Mesh)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Contenido principal
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _BlurBlob extends StatelessWidget {
  const _BlurBlob({required this.color, required this.width});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
