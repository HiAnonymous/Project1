enum QuestionType { text, image }

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctAnswer;
  final QuestionType type;
  final String? imageUrl;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswer,
    required this.type,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'correctAnswer': correctAnswer,
    'type': type.toString(),
    'imageUrl': imageUrl,
  };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'],
    text: json['text'],
    options: List<String>.from(json['options']),
    correctAnswer: json['correctAnswer'],
    type: QuestionType.values.firstWhere((e) => e.toString() == json['type']),
    imageUrl: json['imageUrl'],
  );
} 