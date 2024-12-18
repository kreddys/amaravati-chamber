import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

class BaseMapLayer extends StatefulWidget {
  const BaseMapLayer({Key? key}) : super(key: key);

  @override
  State<BaseMapLayer> createState() => _BaseMapLayerState();
}

class _BaseMapLayerState extends State<BaseMapLayer> {
  late final Future<PmTilesVectorTileProvider> _baseTileProvider;

  @override
  void initState() {
    super.initState();
    _baseTileProvider = PmTilesVectorTileProvider.fromSource(
      'https://kmisqlvoiofymxicxiwv.supabase.co/storage/v1/object/public/maps/amaravati_base.pmtiles',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PmTilesVectorTileProvider>(
      future: _baseTileProvider,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return VectorTileLayer(
            tileProviders: TileProviders({
              'protomaps': snapshot.data!,
            }),
            theme: ProtomapsThemes.light(),
          );
        }
        return const SizedBox();
      },
    );
  }
}
