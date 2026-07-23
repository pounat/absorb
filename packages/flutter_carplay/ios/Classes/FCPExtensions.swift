//
//  FCPExtensions.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import UIKit
import ImageIO

// Image Source (no UIImage creation here)
enum ImageSource {
    case url(URL)
    case file(String)
    case flutterAsset(String)
}

// String → ImageSource
extension String {
    func toImageSource() -> ImageSource? {
        guard !self.isEmpty,
              self.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return nil
        }
        let lowercased = self.lowercased()
        if lowercased.starts(with: "http") {
            guard let url = URL(string: self),
                  let scheme = url.scheme?.lowercased(),
                  (scheme == "http" || scheme == "https"),
                  let host = url.host,
                  !host.isEmpty else {
                return nil
            }
            return .url(url)
        } else if lowercased.starts(with: "file://") {
            guard let url = URL(string: self), url.isFileURL, !url.path.isEmpty else {
                return nil
            }
            return .file(url.path)
        } else if self.contains("://") {
            return nil
        } else {
            return .flutterAsset(self)
        }
    }
}

func makeSafeUIPlaceholder() -> UIImage {
  if Thread.isMainThread {
    return makeUIPlaceholder()
  } else {
    return DispatchQueue.main.sync {
      makeUIPlaceholder()
    }
  }
}

func makeUIPlaceholder() -> UIImage {
  UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 0)
  let img = UIGraphicsGetImageFromCurrentImageContext()!
  UIGraphicsEndImageContext()
  return img
}

// UIImage creation (MAIN THREAD ONLY)
@available(iOS 14.0, *)
func makeUIImage(from source: ImageSource) -> UIImage {
    switch source {
    case .url(let url):
        let data = try? Data(contentsOf: url) // Synchronous URL loading (kept for compatibility but avoid using on main thread)
        return data.flatMap { UIImage(data: $0) } ?? UIImage(systemName: "questionmark")!

    case .file(let path):
        return UIImage(contentsOfFile: path) ?? UIImage(systemName: "questionmark")!

    case .flutterAsset(let name):
        let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
        return UIImage(imageLiteralResourceName: key)
    }
}

// ─── Absorb local patch: downsampled + cached CarPlay list thumbnails ───
//
// The stock plugin decoded every cover at full resolution and started a load
// for every item the moment a list was built. A large list (e.g. an
// alphabetical browse) decoded ~100 multi-megabyte images at once and ran
// CarPlay out of its tight memory budget. We downsample to a small thumbnail
// at decode time (the real fix) and cache the result so re-navigating is
// instant. URLSession's per-host connection limit keeps concurrent loads in
// check.
private let fcpThumbnailCache: NSCache<NSURL, UIImage> = {
    let cache = NSCache<NSURL, UIImage>()
    cache.countLimit = 300
    return cache
}()

// CarPlay list rows are small; 240px is sharp at @3x while keeping each decoded
// image near ~230 KB instead of several MB.
private let fcpThumbnailMaxPixels = 240

private func fcpDownsample(_ source: CGImageSource, maxPixelSize: Int) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]
    guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
    return UIImage(cgImage: cg)
}

private func fcpDownsampledImage(data: Data, maxPixelSize: Int) -> UIImage? {
    let opts: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let src = CGImageSourceCreateWithData(data as CFData, opts as CFDictionary) else { return nil }
    return fcpDownsample(src, maxPixelSize: maxPixelSize)
}

private func fcpDownsampledImage(fileURL: URL, maxPixelSize: Int) -> UIImage? {
    let opts: [CFString: Any] = [kCGImageSourceShouldCache: false]
    guard let src = CGImageSourceCreateWithURL(fileURL as CFURL, opts as CFDictionary) else { return nil }
    return fcpDownsample(src, maxPixelSize: maxPixelSize)
}

// Asynchronous image loader. Always calls completion on main thread.
@available(iOS 14.0, *)
func loadUIImageAsync(from source: ImageSource, completion: @escaping (UIImage?) -> Void) {
    switch source {
    case .url(let url):
        if let cached = fcpThumbnailCache.object(forKey: url as NSURL) {
            DispatchQueue.main.async { completion(cached) }
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            var image: UIImage? = nil
            if let data = data {
                // Downsample at decode time; fall back to a full decode only if
                // the source can't produce a thumbnail.
                image = fcpDownsampledImage(data: data, maxPixelSize: fcpThumbnailMaxPixels) ?? UIImage(data: data)
            }
            if let image = image {
                fcpThumbnailCache.setObject(image, forKey: url as NSURL)
                DispatchQueue.main.async { completion(image) }
            } else {
                DispatchQueue.main.async { completion(UIImage(systemName: "questionmark")) }
            }
        }
        task.resume()

    case .file(let path):
        DispatchQueue.global(qos: .userInitiated).async {
            let image = fcpDownsampledImage(fileURL: URL(fileURLWithPath: path), maxPixelSize: fcpThumbnailMaxPixels)
                ?? UIImage(contentsOfFile: path)
                ?? UIImage(systemName: "questionmark")
            DispatchQueue.main.async { completion(image) }
        }

    case .flutterAsset(let name):
        DispatchQueue.main.async {
            let key = SwiftFlutterCarplayPlugin.registrar!.lookupKey(forAsset: name)
            let image = UIImage(imageLiteralResourceName: key)
            completion(image)
        }
    }
}

//  UIImage utilities (safe, UI only)
extension UIImage {
    func resizeImageTo(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
}

// Regex helper
extension String {
    func match(_ regex: String) -> [[String]] {
        let nsString = self as NSString
        return (try? NSRegularExpression(pattern: regex))?
            .matches(in: self, range: NSRange(location: 0, length: nsString.length))
            .map { match in
                (0..<match.numberOfRanges).map {
                    match.range(at: $0).location == NSNotFound
                    ? ""
                    : nsString.substring(with: match.range(at: $0))
                }
            } ?? []
    }
}
