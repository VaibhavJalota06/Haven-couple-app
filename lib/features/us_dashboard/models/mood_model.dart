class MoodModel {
  final String id;
  final String label;
  final String emoji;
  final String description;

  const MoodModel({
    required this.id,
    required this.label,
    required this.emoji,
    required this.description,
  });

  static const List<MoodModel> presetMoods = [
    MoodModel(id: 'loved', label: 'Loved', emoji: '🥰', description: 'Feeling deeply connected & cherished'),
    MoodModel(id: 'happy', label: 'Happy', emoji: '✨', description: 'In high spirits & bright energy'),
    MoodModel(id: 'missing_you', label: 'Missing You', emoji: '🥺', description: 'Thinking of you constantly'),
    MoodModel(id: 'romantic', label: 'Romantic', emoji: '🌹', description: 'In a dreamy romantic mood'),
    MoodModel(id: 'need_hugs', label: 'Need Hugs', emoji: '🫂', description: 'Could use extra love & warmth'),
    MoodModel(id: 'chill', label: 'Peaceful', emoji: '☕', description: 'Relaxed, calm and content'),
    MoodModel(id: 'tired', label: 'Tired', emoji: '😴', description: 'Low energy, resting up'),
    MoodModel(id: 'busy', label: 'Focused', emoji: '💻', description: 'Working or concentrating right now'),
  ];
}
