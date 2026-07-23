part of 'hotels_cubit.dart';

abstract class HotelsState extends Equatable {
  const HotelsState();
  @override
  List<Object?> get props => [];
}

class HotelsLoading extends HotelsState {
  const HotelsLoading();
}

class HotelsLoaded extends HotelsState {
  final List<HotelEntity> hotels;

  const HotelsLoaded({required this.hotels});

  @override
  List<Object?> get props => [hotels];
}

class HotelsError extends HotelsState {
  final String message;
  const HotelsError(this.message);
  @override
  List<Object?> get props => [message];
}
