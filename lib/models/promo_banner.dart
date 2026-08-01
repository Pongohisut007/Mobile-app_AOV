/// แบนเนอร์โปรโมชันด้านบนของหน้า Home
class PromoBanner {
  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String imageUrl;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.imageUrl,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'].toString(),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      actionLabel: json['action_label'] as String? ?? 'Order Now',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }
}
