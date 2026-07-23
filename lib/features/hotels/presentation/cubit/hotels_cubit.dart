import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel_entity.dart';
import '../../domain/repositories/hotel_repository.dart';

part 'hotels_state.dart';

class HotelsCubit extends Cubit<HotelsState> {
  final HotelRepository _repository;

  HotelsCubit({required HotelRepository repository})
      : _repository = repository,
        super(const HotelsLoading());

  Future<void> loadHotels(String tripId) async {
    emit(const HotelsLoading());

    final result = await _repository.getHotelsForTrip(tripId);
    result.fold(
      (failure) => emit(HotelsError(failure.message)),
      (hotels) => emit(HotelsLoaded(hotels: hotels)),
    );
  }
}
