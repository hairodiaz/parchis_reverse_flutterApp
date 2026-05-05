// 📱 UTILIDADES PARA RESPONSIVE DESIGN
import 'package:flutter/material.dart';

class ResponsiveUtils {
  static const double _baseWidth = 390.0; // iPhone 12/13/14 reference
  
  // Obtener información detallada sobre responsive
  static String getDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final scaleFactor = screenWidth / _baseWidth;
    
    return '''
📱 Información de Pantalla:
• Ancho: ${screenWidth.toStringAsFixed(0)}px
• Alto: ${screenHeight.toStringAsFixed(0)}px
• Factor de escala: ${scaleFactor.toStringAsFixed(2)}x
• Tipo: ${_getScreenType(screenWidth)}
• DPI: ${mediaQuery.devicePixelRatio.toStringAsFixed(1)}
    ''';
  }
  
  static String _getScreenType(double width) {
    if (width < 360) return "Muy pequeña";
    if (width < 390) return "Pequeña";
    if (width < 430) return "Mediana";
    if (width < 600) return "Grande";
    return "Muy grande";
  }
  
  // Debug widget para mostrar información responsive
  static Widget buildDebugInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Text(
        getDeviceInfo(context),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}