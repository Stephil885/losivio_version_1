//  forms/components/filters.dart

import 'package:flutter/material.dart';

/// Définit la catégorie technique du filtre
enum FilterType { color, ar, distortion }

enum CameraFilter {
  none,
  sepia,
  grayscale,
  vintage,
  cinema,
  warm,
  cool,
  highContrast,
  pinkRomantic,
  forestGreen,
  cyberpunk,
  vibrant,
  lemonade,
  deepNight,
  retro80s,
  dawn,
  mars,
  aquarium,
  goldRush,
  polaroid,
  twilight,
  noir,
  acid,
  candy,
  oldTV,
  // --- Nouveaux filtres Spéciaux (AR & Distortion) ---
  mustache,    
  coolGlasses, 
  alien,       
  bigNose      
}

extension CameraFilterExtension on CameraFilter {
  String get label {
    switch (this) {
      case CameraFilter.none: return "Naturel";
      case CameraFilter.sepia: return "Sépia";
      case CameraFilter.grayscale: return "Noir & B";
      case CameraFilter.vintage: return "Vintage";
      case CameraFilter.cinema: return "Cinéma";
      case CameraFilter.warm: return "Chaud";
      case CameraFilter.cool: return "Froid";
      case CameraFilter.highContrast: return "Drame";
      case CameraFilter.pinkRomantic: return "Rosé";
      case CameraFilter.forestGreen: return "Forêt";
      case CameraFilter.cyberpunk: return "Néon";
      case CameraFilter.vibrant: return "Vif";
      case CameraFilter.lemonade: return "Citron";
      case CameraFilter.deepNight: return "Nuit";
      case CameraFilter.retro80s: return "80s";
      case CameraFilter.dawn: return "Aube";
      case CameraFilter.mars: return "Mars";
      case CameraFilter.aquarium: return "Lagon";
      case CameraFilter.goldRush: return "Or";
      case CameraFilter.polaroid: return "Pola";
      case CameraFilter.twilight: return "Crépuscule";
      case CameraFilter.noir: return "Noir";
      case CameraFilter.acid: return "Acide";
      case CameraFilter.candy: return "Candy";
      case CameraFilter.oldTV: return "TV";
      case CameraFilter.mustache: return "Moustache";
      case CameraFilter.coolGlasses: return "Style";
      case CameraFilter.alien: return "Alien";
      case CameraFilter.bigNose: return "Gros Nez";
    }
  }

  FilterType get type {
    switch (this) {
      case CameraFilter.mustache:
      case CameraFilter.coolGlasses:
        return FilterType.ar;
      case CameraFilter.alien:
      case CameraFilter.bigNose:
        return FilterType.distortion;
      default:
        return FilterType.color;
    }
  }

  String get previewUrl => "https://i.pravatar.cc/150?u=${index + 42}";
}

ColorFilter getColorFilter(CameraFilter filter) {
  switch (filter) {
    case CameraFilter.sepia:
      return const ColorFilter.matrix([0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.grayscale:
      return const ColorFilter.matrix([0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.vintage:
      return const ColorFilter.matrix([0.9, 0.1, 0.1, 0, 0, 0.1, 0.8, 0.1, 0, 0, 0.1, 0.1, 0.7, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.cinema:
      return const ColorFilter.matrix([1.2, 0, 0, 0, -0.05, 0, 1.1, 0, 0, -0.05, 0, 0, 1.3, 0, -0.1, 0, 0, 0, 1, 0]);
    case CameraFilter.warm:
      return const ColorFilter.matrix([1.2, 0, 0, 0, 0, 0, 1.1, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.cool:
      return const ColorFilter.matrix([0.9, 0, 0, 0, 0, 0, 0.95, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.highContrast:
      return const ColorFilter.matrix([1.5, 0, 0, 0, -0.1, 0, 1.5, 0, 0, -0.1, 0, 0, 1.5, 0, -0.1, 0, 0, 0, 1, 0]);
    case CameraFilter.pinkRomantic:
      return const ColorFilter.matrix([1, 0, 0.2, 0, 0, 0, 1, 0.1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.forestGreen:
      return const ColorFilter.matrix([0.9, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.cyberpunk:
      return const ColorFilter.matrix([1, 0, 0, 0, 50, 0, 0.8, 0, 0, 0, 0, 0, 1.5, 0, 50, 0, 0, 0, 1, 0]);
    case CameraFilter.vibrant:
      return const ColorFilter.matrix([1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.lemonade:
      return const ColorFilter.matrix([1.1, 0, 0, 0, 0, 0, 1.1, 0, 0, 20, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.deepNight:
      return const ColorFilter.matrix([0.5, 0, 0, 0, 0, 0, 0.6, 0, 0, 0, 0, 0, 0.9, 0, 20, 0, 0, 0, 1, 0]);
    case CameraFilter.retro80s:
      return const ColorFilter.matrix([1.1, 0, 0.2, 0, 0, 0.1, 0.9, 0.3, 0, 0, 0.5, 0, 1.2, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.dawn:
      return const ColorFilter.matrix([1.3, 0, 0, 0, 10, 0, 1.0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.mars:
      return const ColorFilter.matrix([1.5, 0.2, 0, 0, 30, 0.2, 0.8, 0, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, 0, 1, 0]);
    case CameraFilter.aquarium:
      return const ColorFilter.matrix([0.5, 0, 0, 0, 0, 0, 1.2, 0, 0, 20, 0, 0.5, 1.5, 0, 40, 0, 0, 0, 1, 0]);
    case CameraFilter.goldRush:
      return const ColorFilter.matrix([1.2, 0.1, 0, 0, 40, 0, 1.1, 0, 0, 20, 0, 0, 0.6, 0, -20, 0, 0, 0, 1, 0]);
    case CameraFilter.polaroid:
      return const ColorFilter.matrix([1.1, 0, 0, 0, 10, 0, 0.9, 0, 0, 10, 0, 0, 0.8, 0, 20, 0, 0, 0, 1, 0]);
    case CameraFilter.twilight:
      return const ColorFilter.matrix([0.7, 0, 0.3, 0, 20, 0, 0.6, 0.2, 0, 10, 0.4, 0, 1.2, 0, 30, 0, 0, 0, 1, 0]);
    case CameraFilter.noir:
      return const ColorFilter.matrix([1.8, 1.8, 1.8, 0, -150, 1.8, 1.8, 1.8, 0, -150, 1.8, 1.8, 1.8, 0, -150, 0, 0, 0, 1, 0]);
    case CameraFilter.acid:
      return const ColorFilter.matrix([0.5, 2, 0, 0, -50, 0, 0.5, 2, 0, -50, 2, 0, 0.5, 0, -50, 0, 0, 0, 1, 0]);
    case CameraFilter.candy:
      return const ColorFilter.matrix([1, 0.3, 0.3, 0, 20, 0.3, 1, 0.3, 0, 20, 0.3, 0.3, 1, 0, 20, 0, 0, 0, 1, 0]);
    case CameraFilter.oldTV:
      return const ColorFilter.matrix([0.9, 0, 0, 0, 5, 0, 1.1, 0, 0, 5, 0, 0, 1.1, 0, 10, 0, 0, 0, 1, 0]);
    case CameraFilter.none:
    default:
      return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
  }
}
// Ajoute cette fonction tout en bas de filters.dart (ou juste après getColorFilter)
Widget buildFilterPreview(CameraFilter filter) {
  if (filter.type == FilterType.color) {
    return ColorFiltered(
      colorFilter: getColorFilter(filter),
      child: Image.network(
        filter.previewUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
      ),
    );
  }

  return Stack(
    fit: StackFit.expand,
    children: [
      Image.network(filter.previewUrl, fit: BoxFit.cover),
      Container(color: Colors.black26),
      Icon(
        filter.type == FilterType.ar ? Icons.face_retouching_natural : Icons.auto_fix_high,
        color: Colors.white70,
        size: 20,
      ),
    ],
  );
}

class FilterSelector extends StatelessWidget {
  final CameraFilter selectedFilter;
  final Function(CameraFilter) onFilterSelected;

  const FilterSelector({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: CameraFilter.values.length,
        itemBuilder: (context, index) {
          final filter = CameraFilter.values[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () => onFilterSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              curve: Curves.easeOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white24,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 10)]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: ClipOval(
                        // ON UTILISE LA FONCTION GLOBALE ICI AUSSI
                        child: buildFilterPreview(filter), 
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    filter.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreview(CameraFilter filter) {
    if (filter.type == FilterType.color) {
      return ColorFiltered(
        colorFilter: getColorFilter(filter),
        child: Image.network(
          filter.previewUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
        ),
      );
    } 
    
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(filter.previewUrl, fit: BoxFit.cover),
        Container(color: Colors.black26),
        Icon(
          // Correction ici : auto_fix_high au lieu de Auto_fix_high
          filter.type == FilterType.ar ? Icons.face_retouching_natural : Icons.auto_fix_high,
          color: Colors.white70,
          size: 20,
        ),
      ],
    );
  }
}