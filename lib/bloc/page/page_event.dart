class PageEvent {}

class PageChangeEvent extends PageEvent {
  PageChangeEvent(this.pageIndex);
  // index of the page to switch to
  final int pageIndex;
}
