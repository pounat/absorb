class EpubMetadata {
  final String? title;
  final String? author;
  final String? language;
  final String? identifier;
  final String? publisher;
  final String? description;
  final String? date;
  final String? subject;
  final String? coverImage;

  EpubMetadata({
    this.title,
    this.author,
    this.language,
    this.identifier,
    this.publisher,
    this.description,
    this.date,
    this.subject,
    this.coverImage,
  });

  factory EpubMetadata.fromJson(Map<String, dynamic> json) {
    return EpubMetadata(
      title: json['title'] as String?,
      author: json['author'] as String?,
      language: json['language'] as String?,
      identifier: json['identifier'] as String?,
      publisher: json['publisher'] as String?,
      description: json['description'] as String?,
      date: json['date'] as String?,
      subject: json['subject'] as String?,
      coverImage: json['coverImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'language': language,
      'identifier': identifier,
      'publisher': publisher,
      'description': description,
      'date': date,
      'subject': subject,
      'coverImage': coverImage,
    };
  }
}
