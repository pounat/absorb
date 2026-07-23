//
//  FCPListItem.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

@available(iOS 14.0, *)
class FCPListItem {
  private(set) var _super: CPListItem?
  private(set) var elementId: String
  private var text: String
  private var detailText: String?
  private var isOnPressListenerActive: Bool = false
  private var completeHandler: (() -> Void)?
  private var image: String?
  private var playbackProgress: CGFloat?
  private var isPlaying: Bool?
  private var playingIndicatorLocation: CPListItemPlayingIndicatorLocation?
  private var accessoryType: CPListItemAccessoryType?
  
  init(obj: [String : Any]) {
    self.elementId = obj["_elementId"] as! String
    self.text = obj["text"] as! String
    self.detailText = obj["detailText"] as? String
    self.isOnPressListenerActive = obj["onPress"] as? Bool ?? false
    self.image = obj["image"] as? String
    self.playbackProgress = obj["playbackProgress"] as? CGFloat
    self.isPlaying = obj["isPlaying"] as? Bool
    self.setPlayingIndicatorLocation(fromString: obj["playingIndicatorLocation"] as? String)
    self.setAccessoryType(fromString: obj["accessoryType"] as? String)
  }

  private func handler(selectedItem: CPSelectableListItem, complete: @escaping () -> Void) {
    if isOnPressListenerActive {
      completeHandler = complete

      DispatchQueue.main.async {
        FCPStreamHandlerPlugin.sendEvent(
          type: FCPChannelTypes.onListItemSelected,
          data: ["elementId": self.elementId]
        )
      }
    } else {
      complete()
    }
  }

  var get: CPListItem {
    let listItem = CPListItem.init(text: text, detailText: detailText)
    listItem.handler = self.handler
    if let imageSource = image?.toImageSource() {
      listItem.setImage(makeSafeUIPlaceholder())
      loadUIImageAsync(from: imageSource) { uiImage in
        if let uiImage = uiImage {
          listItem.setImage(uiImage)
        }
      }
    }
    if playbackProgress != nil {
      listItem.playbackProgress = playbackProgress!
    }
    if isPlaying != nil {
      listItem.isPlaying = isPlaying!
    }
    if playingIndicatorLocation != nil {
      listItem.playingIndicatorLocation = playingIndicatorLocation!
    }
    if accessoryType != nil {
      listItem.accessoryType = accessoryType!
    }
    self._super = listItem
    return listItem
  }
  
  public func stopHandler() {
    guard self.completeHandler != nil else {
      return
    }
    self.completeHandler!()
    self.completeHandler = nil
  }
  
  public func update(text: String?, detailText: String?, image: String?, playbackProgress: CGFloat?, isPlaying: Bool?, playingIndicatorLocation: String?, accessoryType: String?) {
    if text != nil {
      self._super?.setText(text!)
      self.text = text!
    }
    if detailText != nil {
      self._super?.setDetailText(detailText)
      self.detailText = detailText
    }

    if let image = image, image != self.image {
      if let imageSource = image.toImageSource() {
        self._super?.setImage(makeSafeUIPlaceholder())
        loadUIImageAsync(from: imageSource) { uiImage in
          if let uiImage = uiImage {
            self._super?.setImage(uiImage)
          }
        }
      } else {
        self._super?.setImage(nil)
      }
      self.image = image
    } else if image == nil {
      self.image = nil
      self._super?.setImage(nil)
    }

    if playbackProgress != nil {
      self._super?.playbackProgress = playbackProgress!
      self.playbackProgress = playbackProgress
    }
    if isPlaying != nil {
      self._super?.isPlaying = isPlaying!
      self.isPlaying = isPlaying
    }
    if playingIndicatorLocation != nil {
      self.setPlayingIndicatorLocation(fromString: playingIndicatorLocation)
      if self.playingIndicatorLocation != nil {
        self._super?.playingIndicatorLocation = self.playingIndicatorLocation!
      }
    }
    if accessoryType != nil {
      self.setAccessoryType(fromString: accessoryType)
      if self.accessoryType != nil {
        self._super?.accessoryType = self.accessoryType!
      }
    }
  }
  
  private func setPlayingIndicatorLocation(fromString: String?) {
    if fromString == "leading" {
      self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.leading
    } else if fromString == "trailing" {
      self.playingIndicatorLocation = CPListItemPlayingIndicatorLocation.trailing
    }
  }
  
  private func setAccessoryType(fromString: String?) {
    if fromString == "cloud" {
      self.accessoryType = CPListItemAccessoryType.cloud
    } else if fromString == "disclosureIndicator" {
      self.accessoryType = CPListItemAccessoryType.disclosureIndicator
    } else {
      self.accessoryType = CPListItemAccessoryType.none
    }
  }

  public func merge(with: FCPListItem) -> FCPListItem {
    with._super = self._super
    with._super?.handler = with.handler
    return with;
  }
}
