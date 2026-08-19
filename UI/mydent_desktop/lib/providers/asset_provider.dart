import '../models/asset.dart';
import 'base_provider.dart';

class AssetProvider extends BaseProvider<Asset> {
  AssetProvider() : super("Assets");

  @override
  Asset fromJson(data) => Asset.fromJson(data as Map<String, dynamic>);
}
