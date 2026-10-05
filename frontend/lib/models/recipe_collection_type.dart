import 'package:flutter_application_1/l10n/l10n.dart';

enum RecipeCollectionType { myRecipes, purchased, favorites, drafts }

extension RecipeCollectionTypeText on RecipeCollectionType {
  String title(AppLocalizations l10n) => switch (this) {
    RecipeCollectionType.myRecipes => l10n.myRecipes,
    RecipeCollectionType.purchased => l10n.purchasedRecipes,
    RecipeCollectionType.favorites => l10n.favorites,
    RecipeCollectionType.drafts => l10n.drafts,
  };

  String emptyMessage(AppLocalizations l10n) => switch (this) {
    RecipeCollectionType.myRecipes => l10n.collectionEmptyMyRecipes,
    RecipeCollectionType.purchased => l10n.collectionEmptyPurchased,
    RecipeCollectionType.favorites => l10n.collectionEmptyFavorites,
    RecipeCollectionType.drafts => l10n.collectionEmptyDrafts,
  };
}
