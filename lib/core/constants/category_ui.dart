/// Single source of truth for the stop-category → emoji mapping, shared by
/// [StopEntity.categoryEmoji] (domain) and [CategoryChip] (shared widget) so
/// a new category only needs to be added here to show consistently everywhere.
String stopCategoryEmoji(String category) => switch (category) {
      'museum' => '🏛️',
      'restaurant' => '🍽️',
      'park' => '🌿',
      'shopping' => '🛍️',
      'landmark' => '🗺️',
      'beach' => '🏖️',
      'mosque' => '🕌',
      'palace' => '🏰',
      'market' => '🏪',
      'viewpoint' => '🔭',
      _ => '📍',
    };
