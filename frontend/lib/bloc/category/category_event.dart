abstract class CategoryEvent {
  CategoryEvent();
}

class FetchCategoriesEvent extends CategoryEvent {
  FetchCategoriesEvent();
}

class CategorySelectEvent extends CategoryEvent {
  // slug ของ category ที่กด (กดซ้ำอันเดิม = ยกเลิกการกรอง)
  final String slug;
  CategorySelectEvent(this.slug);
}
