enum ActivityType {
  runner,
  walker,
}

extension ActivityTypeFirestore on ActivityType {
  String get asFirestoreValue => name;
}
