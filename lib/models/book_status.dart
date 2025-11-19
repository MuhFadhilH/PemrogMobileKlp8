enum BookStatus { none, wantToRead, currentlyReading, finished }

extension BookStatusExtension on BookStatus {
  String toDisplayString() {
    switch (this) {
      case BookStatus.wantToRead:
        return 'Ingin Dibaca';
      case BookStatus.currentlyReading:
        return 'Sedang Dibaca';
      case BookStatus.finished:
        return 'Selesai Dibaca';
      case BookStatus.none:
        return 'Belum Ditambahkan';
    }
  }

  String toFirestoreString() {
    return name;
  }

  static BookStatus fromFirestoreString(String? status) {
    if (status == null) return BookStatus.none;
    switch (status) {
      case 'wantToRead':
        return BookStatus.wantToRead;
      case 'currentlyReading':
        return BookStatus.currentlyReading;
      case 'finished':
        return BookStatus.finished;
      default:
        return BookStatus.none;
    }
  }
}
