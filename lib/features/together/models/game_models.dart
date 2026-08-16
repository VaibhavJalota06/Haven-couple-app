class WouldYouRatherQuestion {
  final String id;
  final String optionA;
  final String optionB;

  const WouldYouRatherQuestion({
    required this.id,
    required this.optionA,
    required this.optionB,
  });

  static const List<WouldYouRatherQuestion> defaultQuestions = [
    WouldYouRatherQuestion(
      id: 'wyr_1',
      optionA: 'Spend a cozy rainy weekend indoors watching movies',
      optionB: 'Go on an unplanned road trip to the mountains',
    ),
    WouldYouRatherQuestion(
      id: 'wyr_2',
      optionA: 'Never have to cook dinner again',
      optionB: 'Never have to clean dishes or do laundry again',
    ),
    WouldYouRatherQuestion(
      id: 'wyr_3',
      optionA: 'Travel back in time to our first date',
      optionB: 'Fast-forward 10 years into our future dream home',
    ),
    WouldYouRatherQuestion(
      id: 'wyr_4',
      optionA: 'Always know what your partner is thinking',
      optionB: 'Always know how to make your partner laugh',
    ),
    WouldYouRatherQuestion(
      id: 'wyr_5',
      optionA: 'Live on a quiet beach with no neighbors',
      optionB: 'Live in a bustling penthouse in Tokyo or Paris',
    ),
  ];
}

class TruthOrDareCard {
  final String id;
  final String content;
  final bool isTruth;

  const TruthOrDareCard({
    required this.id,
    required this.content,
    required this.isTruth,
  });

  static const List<TruthOrDareCard> defaultCards = [
    TruthOrDareCard(
      id: 't_1',
      content: 'What was the exact moment you realized you had feelings for me?',
      isTruth: true,
    ),
    TruthOrDareCard(
      id: 't_2',
      content: 'What is your favorite memory of us that you cherish the most?',
      isTruth: true,
    ),
    TruthOrDareCard(
      id: 't_3',
      content: 'What is one little habit of mine that secretly makes you smile?',
      isTruth: true,
    ),
    TruthOrDareCard(
      id: 'd_1',
      content: 'Give your partner a 60-second back or shoulder massage right now.',
      isTruth: false,
    ),
    TruthOrDareCard(
      id: 'd_2',
      content: 'Whisper three things you love about your partner in their ear.',
      isTruth: false,
    ),
    TruthOrDareCard(
      id: 'd_3',
      content: 'Play our special song and slow dance for 2 minutes.',
      isTruth: false,
    ),
  ];
}
