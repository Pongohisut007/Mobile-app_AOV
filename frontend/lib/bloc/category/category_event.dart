class CategoryEvent {}

class CategorySelectEvent extends CategoryEvent {
  CategorySelectEvent(this.category);
  final String category;
}