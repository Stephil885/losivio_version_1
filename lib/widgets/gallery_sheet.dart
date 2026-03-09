// losivio/lib/widgets/gallery_sheet.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class GallerySheet extends StatefulWidget {
  const GallerySheet({super.key});

  @override
  State<GallerySheet> createState() => _GallerySheetState();
}

class _GallerySheetState extends State<GallerySheet> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  final List<AssetEntity> _selectedAssets = [];

  @override
  void initState() {
    super.initState();
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    // Demande de permission étendue pour accéder aux vidéos et photos
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _isLoading = false);
      return;
    }

    // On demande explicitement les photos et vidéos
    List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.common, // Common = Video + Image
      filterOption: FilterOptionGroup(
        videoOption: const FilterOption(
          durationConstraint: DurationConstraint(min: Duration(seconds: 1)),
        ),
      ),
    );

    if (albums.isNotEmpty) {
      // FIX : On cherche l'album "Tous les médias" (isAll) au lieu de prendre albums[0] par défaut
      // car albums[0] peut être un dossier spécifique sans vidéos.
      final AssetPathEntity recentAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums[0],
      );

      // Chargement des 100 derniers médias (ordre chronologique inverse par défaut)
      List<AssetEntity> media = await recentAlbum.getAssetListPaged(
        page: 0, 
        size: 100,
      );

      setState(() {
        _assets = media;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAssetSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // --- Barre de poignée (Drag Handle) ---
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          
          // --- Titre et Bouton de confirmation ---
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedAssets.isEmpty 
                    ? "Galerie" 
                    : "${_selectedAssets.length} sélectionné(s)",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_selectedAssets.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      List<String> paths = [];
                      for (var asset in _selectedAssets) {
                        File? file = await asset.file;
                        if (file != null) {
                          paths.add(file.path);
                        }
                      }
                      if (context.mounted) {
                        Navigator.pop(context, paths);
                      }
                    },
                    child: const Text(
                      "Confirmer",
                      style: TextStyle(
                        color: Colors.blueAccent, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- Grille de médias ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _assets.isEmpty
                    ? const Center(
                        child: Text("Aucun média trouvé", style: TextStyle(color: Colors.grey)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(2),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          final isSelected = _selectedAssets.contains(asset);

                          return _MediaTile(
                            asset: asset,
                            isSelected: isSelected,
                            selectionIndex: isSelected ? _selectedAssets.indexOf(asset) + 1 : null,
                            onTap: () => _toggleAssetSelection(asset),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final int? selectionIndex;
  final VoidCallback onTap;

  const _MediaTile({
    required this.asset, 
    required this.onTap,
    required this.isSelected,
    this.selectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Affichage de la miniature
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                return ColorFiltered(
                  colorFilter: isSelected
                      ? ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)
                      : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                  child: Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                  ),
                );
              }
              return Container(color: Colors.grey[900]);
            },
          ),
          
          // Indicateur de sélection
          Positioned(
            top: 8,
            right: 8,
            child: isSelected 
              ? Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$selectionIndex',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const Icon(Icons.circle_outlined, color: Colors.white, size: 24),
          ),

          // Icône Vidéo + Durée
          if (asset.type == AssetType.video)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      _formatDuration(asset.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}