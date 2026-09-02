enum MapLayerType {
  osm(
    id: 'osm',
    name: 'Схема OpenStreetMap',
    subtitle: 'Детальные дороги, тропы и населенные пункты (до 19 уровня)',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxNativeZoom: 18,
    minZoom: 3.0,
    maxZoom: 19.0,
  ),
  arcgisTopo(
    id: 'arcgis_topo',
    name: 'ArcGIS Топокарта',
    subtitle: 'Рельеф, высоты и изолинии местности',
    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: 15,
    minZoom: 3.0,
    maxZoom: 19.0,
  ),
  openTopo(
    id: 'open_topo',
    name: 'OpenTopoMap',
    subtitle: 'Туристическая топографическая карта',
    urlTemplate: 'https://a.tile.opentopomap.org/{z}/{x}/{y}.png',
    maxNativeZoom: 15,
    minZoom: 3.0,
    maxZoom: 18.0,
  ),
  satellite(
    id: 'satellite',
    name: 'Спутник (ArcGIS Imagery)',
    subtitle: 'Детальные спутниковые аэрофотоснимки',
    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    maxNativeZoom: 17,
    minZoom: 3.0,
    maxZoom: 19.0,
  );

  final String id;
  final String name;
  final String subtitle;
  final String urlTemplate;
  final int maxNativeZoom;
  final double minZoom;
  final double maxZoom;

  const MapLayerType({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.urlTemplate,
    required this.maxNativeZoom,
    required this.minZoom,
    required this.maxZoom,
  });
}
