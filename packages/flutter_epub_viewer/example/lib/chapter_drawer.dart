import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter/material.dart';

class ChapterDrawer extends StatefulWidget {
  const ChapterDrawer({super.key, required this.controller});

  final EpubController controller;

  @override
  State<ChapterDrawer> createState() => _ChapterDrawerState();
}

class _ChapterDrawerState extends State<ChapterDrawer> {
  late List<EpubChapter> chapters;

  @override
  void initState() {
    chapters = widget.controller.getChapters();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: ListView.builder(
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(chapters[index].title),
                onTap: () {
                  widget.controller.display(cfi: chapters[index].href);
                  Navigator.pop(context);
                },
              );
            }));
  }
}
