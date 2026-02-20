enum SearchResultType { notes, syllabus, pyq, important }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final String department;
  final int semester;
  final String subject;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.department,
    required this.semester,
    required this.subject,
    required this.metadata,
  });

  factory SearchResult.fromNotes(Map<String, dynamic> data) {
    return SearchResult(
      id: data['id'].toString(),
      title: data['title'] ?? 'Unit ${data['unit']}',
      subtitle: '${data['subject']} · Unit ${data['unit']}',
      type: SearchResultType.notes,
      department: data['department'],
      semester: data['semester'],
      subject: data['subject'],
      metadata: data,
    );
  }

  factory SearchResult.fromSyllabus(Map<String, dynamic> data) {
    return SearchResult(
      id: data['id'].toString(),
      title: data['title'] ?? data['subject'],
      subtitle: '${data['subject']} · Syllabus',
      type: SearchResultType.syllabus,
      department: data['department'],
      semester: data['semester'],
      subject: data['subject'],
      metadata: data,
    );
  }

  factory SearchResult.fromPyq(Map<String, dynamic> data) {
    return SearchResult(
      id: data['id'].toString(),
      title: '${data['subject']} - ${data['year']}',
      subtitle: 'PYQ · ${data['year']}',
      type: SearchResultType.pyq,
      department: data['department'],
      semester: data['semester'],
      subject: data['subject'],
      metadata: data,
    );
  }

  factory SearchResult.fromImportant(Map<String, dynamic> data) {
    return SearchResult(
      id: data['id'].toString(),
      title: data['title'] ?? data['subject'],
      subtitle: '${data['subject']} · Important Questions',
      type: SearchResultType.important,
      department: data['department'],
      semester: data['semester'],
      subject: data['subject'],
      metadata: data,
    );
  }
}
