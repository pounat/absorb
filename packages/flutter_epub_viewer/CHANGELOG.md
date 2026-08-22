## 1.2.8
- Fixed `getCurrentLocation` function

## 1.2.7
- Added `customCss` support in `EpubTheme` for granular styling

## 1.2.6
- Fixed dispose issue ([#71](https://github.com/fayis672/epub_viewer/issues/71))

## 1.2.5
- Added onTouchUp and onTouchDown ([#93](https://github.com/fayis672/epub_viewer/pull/93))
- Add selectAnnotationRange parameter to control annotation selection behavior ([#96](https://github.com/fayis672/epub_viewer/pull/96))
- Block navigation while text is selected ([#92](https://github.com/fayis672/epub_viewer/pull/92))
- Add XPath/XPointer support for EPUB navigation and search ([#89](https://github.com/fayis672/epub_viewer/pull/89))

## 1.2.4
- Initial progress fixes
- Relocation on font change fixes
- background decoration fixes
- Added onSelection callback with WebView-relative coordinates for custom selection UI
- Added onSelectionChanging callback for detecting selection handle dragging
- Added onDeselection callback for selection cleared events
- Added clearSelectionOnPageChange property to control selection behavior on navigation
- Fixed suppressNativeContextMenu to properly hide native context menu
- Fixed text selection coordinate mapping for accurate positioning

## 1.2.3
- iOS chapter parsing fixes

## 1.2.2
- Added book metadata

## 1.2.1
- Fixed book loading issues
- Fixed font size adjust issues
- Added change theme function
- Added navigation to first and last pages

## 1.2.0
- Added Epub Theme with background and foreground color

## 1.1.6
- Remove Highlight fix

## 1.1.5
- LTR -RTL fixes
- Sub chapter parsing fixes
- Fixed `onRelocated` callback on Android
- Changed Default display settings

## 1.1.4

- Size fit fixes

## 1.1.3

- Added reading progress

## 1.1.2

- Added Annotation click handler

## 1.1.1

- Fixed book reloading issues

## 1.1.0

- Added Local file and asset support
- Added underline annotation
- Added text content extraction

## 1.0.2

- Document changes

## 1.0.1

- Fixed blank screen

## 1.0.0

- Highlight text
- Search in Epub
- List chapters
- Text selection
- Highly customizable UI
- Resume reading using cfi
- Custom context menus for selection
