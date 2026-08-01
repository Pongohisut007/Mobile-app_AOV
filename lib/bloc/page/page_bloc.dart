import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/bloc/page/page_event.dart';
import 'package:flutter_application_1/bloc/page/page_state.dart';

class PageBloc extends Bloc<PageEvent, PageState> {
  PageBloc() : super(PageState(selectedPage: 0)) {
    on<PageChangeEvent>((event, emit) {
      emit(PageState(selectedPage: event.pageIndex));
    });
  }
}
