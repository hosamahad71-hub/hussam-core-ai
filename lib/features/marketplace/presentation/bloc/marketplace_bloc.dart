import 'package:flutter_bloc/flutter_bloc.dart';
import 'marketplace_event.dart';
import 'marketplace_state.dart';
import '../../data/repositories/marketplace_repository.dart';

class MarketplaceBloc extends Bloc<MarketplaceEvent, MarketplaceState> {
  final MarketplaceRepository repository;

  MarketplaceBloc(this.repository) : super(MarketplaceInitial()) {
    on<FetchProducts>((event, emit) async {
      emit(MarketplaceLoading());
      try {
        final products = await repository.fetchProducts();
        emit(MarketplaceLoaded(products));
      } catch (e) {
        emit(MarketplaceLoaded([])); // حماية التدفق والتحويل للبيانات الاحتياطية الفخمة
      }
    });
  }
}
