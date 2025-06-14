import 'package:flutter/material.dart';

/// A class representing a highlight option for PDF editing.
///
/// Contains a [tag] for identification, a [name] for display, and a [color] (e.g., hex string).
class HighlightOption {
  /// The tag used to identify the highlight option.
  final String tag;

  /// The display name for the highlight option.
  final String name;

  /// The color of the highlight (e.g., hex string).
  final String color;

  HighlightOption({
    required this.tag,
    required this.name,
    required this.color,
  });

  /// Converts this [HighlightOption] to a map.
  Map<String, dynamic> toMap() {
    return {
      'tag': tag,
      'name': name,
      'color': color,
    };
  }

  /// Creates a [HighlightOption] from a map.
  factory HighlightOption.fromMap(Map<String, dynamic> map) {
    return HighlightOption(
      tag: map['tag'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
    );
  }
}
