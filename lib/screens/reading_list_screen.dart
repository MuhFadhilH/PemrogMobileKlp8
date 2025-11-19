import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';

class ReadingListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar Bacaan Saya')),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          final myBooks = provider.readingList;

          if (myBooks.isEmpty) {
            return Center(child: Text('Belum ada buku yang disimpan'));
          }

          return ListView.builder(
            itemCount: myBooks.length,
            itemBuilder: (context, index) {
              final book = myBooks[index];
              return ListTile(
                leading: Image.network(book.thumbnailUrl, width: 50),
                title: Text(book.title),
                subtitle: Text(book.author),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    provider.toggleReadingList(book);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}