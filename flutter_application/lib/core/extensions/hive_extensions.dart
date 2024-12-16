import 'package:hive/hive.dart';

const _themeBoxName = "themeMode";
const _geojsonBoxName = "geojson";

extension ThemeModeBoxExtension on HiveInterface {
  Future<Box> openThemeModeBox() async {
    return await openBox(_themeBoxName);
  }

  Box get themeModeBox => box(_themeBoxName);
}

extension GeojsonBoxExtension on HiveInterface {
  Future<Box> openGeojsonBox() async {
    return await Hive.openBox(_geojsonBoxName);
  }

  Box get geojsonBox => Hive.box(_geojsonBoxName);
}
