import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, required this.epubController});

  final EpubController epubController;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var query = '';

  var searchResult = <EpubSearchResult>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search',
                ),
                onChanged: (value) async {},
                onSubmitted: (value) {
                  setState(() {
                    query = value;
                  });

                  widget.epubController.search(query: value).then((value) {
                    setState(() {
                      searchResult = value;
                    });
                  });
                },
              ),
              Expanded(
                  child: ListView.builder(
                      itemCount: searchResult.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            widget.epubController
                                .display(cfi: searchResult[index].cfi);
                            Navigator.pop(context);
                          },
                          title: HighlightText(
                              text: searchResult[index].excerpt,
                              highlight: query,
                              style: const TextStyle(),
                              highlightStyle: const TextStyle(
                                backgroundColor: Colors.yellow,
                              )),
                        );
                      }))
            ],
          ),
        ),
      ),
    );
  }
}

class HighlightText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle style;
  final TextStyle highlightStyle;
  final bool ignoreCase;

  const HighlightText({
    super.key,
    required this.text,
    required this.highlight,
    required this.style,
    required this.highlightStyle,
    this.ignoreCase = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if ((highlight.isEmpty) || text.isEmpty) {
      return Text(text, style: style);
    }

    var sourceText = ignoreCase ? text.toLowerCase() : text;
    var targetHighlight = ignoreCase ? highlight.toLowerCase() : highlight;

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;
    do {
      indexOfHighlight = sourceText.indexOf(targetHighlight, start);
      if (indexOfHighlight < 0) {
        // no highlight
        spans.add(_normalSpan(text.substring(start)));
        break;
      }
      if (indexOfHighlight > start) {
        // normal text before highlight
        spans.add(_normalSpan(text.substring(start, indexOfHighlight)));
      }
      start = indexOfHighlight + highlight.length;
      spans.add(_highlightSpan(text.substring(indexOfHighlight, start)));
    } while (true);

    return Text.rich(TextSpan(children: spans));
  }

  TextSpan _highlightSpan(String content) {
    return TextSpan(text: content, style: highlightStyle);
  }

  TextSpan _normalSpan(String content) {
    return TextSpan(text: content, style: style);
  }
}
