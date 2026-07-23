//
//  FCPGridButton.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPGridButton {
  private(set) var _super: CPGridButton?
  private(set) var elementId: String
  private var titleVariants: [String]
  private var image: String
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.titleVariants = obj["titleVariants"] as! [String]
    self.image = obj["image"] as! String
  }
  
  var get: CPGridButton {
    var gridButton: CPGridButton!
    let image: UIImage
    let imageSource = self.image.toImageSource()

    if #available(iOS 26.0, *) {
      image = makeSafeUIPlaceholder()
    } else if let imageSource = imageSource {
      image = makeUIImage(from: imageSource)
    } else {
      image = makeSafeUIPlaceholder()
    }

    gridButton = CPGridButton(
      titleVariants: self.titleVariants,
      image: image,
      handler: { _ in
        DispatchQueue.main.async {
          FCPStreamHandlerPlugin.sendEvent(
            type: FCPChannelTypes.onGridButtonPressed,
            data: ["elementId": self.elementId]
          )
        }
      }
    )

    if #available(iOS 26.0, *), let imageSource = imageSource {
      loadUIImageAsync(from: imageSource) { uiImage in
        if let uiImage = uiImage {
          gridButton.perform(Selector("updateImage:"), with: uiImage)
        }
      }
    }

    gridButton.isEnabled = true
    self._super = gridButton
    return gridButton
  }
}
