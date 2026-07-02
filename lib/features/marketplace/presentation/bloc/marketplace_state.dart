import '../../data/models/product_model.dart';

abstract class MarketplaceState {}

class MarketplaceInitial extends MarketplaceState {}

class MarketplaceLoading extends MarketplaceState {}

class MarketplaceLoaded extends MarketplaceState {
  final List<ProductModel> products;
  MarketplaceLoaded(this.products);
}

class MarketplaceError extends MarketplaceState {
  final String message;
  MarketplaceError(this.message);
}
