import 'package:flutter_bloc/flutter_bloc.dart';
import 'counter_event.dart';
import 'counter_state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterState(counter: 0)) {
    on<IncreaseCounterEvent>((event, emit) {
      int newCounterValue = state.counter + 1;
      emit(CounterState(counter: newCounterValue));
    });
    on<DecreaseCounterEvent>((event, emit) {
      int newCounterValue = state.counter - 1;
      newCounterValue = newCounterValue < 0 ? 0 : newCounterValue;
      emit(CounterState(counter: newCounterValue));
    });
    on<ResetCounterEvent>((event, emit) {
      emit(CounterState(counter: 0));
    });
  }
}
