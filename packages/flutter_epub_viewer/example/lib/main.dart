import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'package:example/chapter_drawer.dart';
import 'package:example/search_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Epub Viewer Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final epubController = EpubController();

  var textSelectionCfi = '';

  bool isLoading = true;

  double progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: ChapterDrawer(
        controller: epubController,
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SearchPage(epubController: epubController),
                  ));
            },
          ),
        ],
      ),
      body: SafeArea(
          child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
          ),
          Expanded(
            child: Stack(
              children: [
                EpubViewer(
                  initialCfi: 'epubcfi(/6/20!/4/2[introduction]/2[c1_h]/1:0)',
                  epubSource: EpubSource.fromUrl(
                      'https://github.com/IDPF/epub3-samples/releases/download/20230704/accessible_epub_3.epub'),
                  epubController: epubController,
                  displaySettings: EpubDisplaySettings(
                      flow: EpubFlow.paginated,
                      useSnapAnimationAndroid: false,
                      snap: true,
                      theme: EpubTheme.light(),
                      allowScriptedContent: true),
                  selectionContextMenu: ContextMenu(
                    menuItems: [
                      ContextMenuItem(
                        title: "Highlight",
                        id: 1,
                        action: () async {
                          epubController.addHighlight(cfi: textSelectionCfi);
                        },
                      ),
                    ],
                    settings: ContextMenuSettings(
                        hideDefaultSystemContextMenuItems: true),
                  ),
                  onChaptersLoaded: (chapters) {
                    setState(() {
                      isLoading = false;
                    });
                  },
                  onEpubLoaded: () async {
                    print('Epub loaded');
                  },
                  onRelocated: (value) {
                    print("Reloacted to $value");
                    setState(() {
                      progress = value.progress;
                    });
                  },
                  onAnnotationClicked: (cfi, data) {
                    print("Annotation clicked $cfi");
                  },
                  onTextSelected: (epubTextSelection) {
                    textSelectionCfi = epubTextSelection.selectionCfi;
                    print(textSelectionCfi);
                  },
                  onLocationLoaded: () {
                    /// progress will be available after this callback
                    print('on location loaded');
                  },
                  onSelection:
                      (selectedText, cfiRange, selectionRect, viewRect) {
                    print("On selection changes");
                  },
                  onDeselection: () {
                    print("on delection");
                  },
                  onSelectionChanging: () {
                    print("on slection chnages");
                  },
                  onTouchDown: (x, y) {
                    print("Touch down at $x , $y");
                  },
                  onTouchUp: (x, y) {
                    print("Touch up at $x , $y");
                  },
                  selectAnnotationRange: true,
                ),
                Visibility(
                  visible: isLoading,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              ],
            ),
          ),
        ],
      )),
    );
  }
}
