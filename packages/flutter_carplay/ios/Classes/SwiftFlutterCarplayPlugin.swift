//
//  SwiftFlutterCarplayPlugin.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import Flutter
import CarPlay

@available(iOS 14.0, *)
public class SwiftFlutterCarplayPlugin: NSObject, FlutterPlugin {
  private static var streamHandler: FCPStreamHandlerPlugin?
  private(set) static var registrar: FlutterPluginRegistrar?
  private static var objcRootTemplate: FCPRootTemplate?
  static var templateStack: [FCPRootTemplate] = []
  private static var _rootTemplate: CPTemplate?
  public static var animated: Bool = false
  private var objcPresentTemplate: FCPPresentTemplate?
  
  public static var rootTemplate: CPTemplate? {
    get {
      return _rootTemplate
    }
    set(tabBarTemplate) {
      _rootTemplate = tabBarTemplate
    }
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: makeFCPChannelId(event: ""),
                                       binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterCarplayPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    self.registrar = registrar
    
    self.streamHandler = FCPStreamHandlerPlugin(registrar: registrar)
  }

  public static func sendOnScreenBackButtonPressed(elementId: String) {
    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onScreenBackButtonPressed, data: ["elementId": elementId])
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case FCPChannelTypes.isConnected:
      result(FlutterCarPlaySceneDelegate.isConnected)
      break
    case FCPChannelTypes.setRootTemplate:
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      var rootTemplate: FCPRootTemplate?
      switch args["runtimeType"] as! String {
          case String(describing: FCPTabBarTemplate.self):
            rootTemplate = FCPTabBarTemplate(obj: args["rootTemplate"] as! [String : Any])
            let tabBarTemplate = rootTemplate as! FCPTabBarTemplate
            if tabBarTemplate.getTemplates().count > CPTabBarTemplate.maximumTabCount {
                result(FlutterError(code: "ERROR",
                                    message: "CarPlay cannot have more than \(CPTabBarTemplate.maximumTabCount) templates on one screen.",
                                    details: nil))
                return
            }
            break
          case String(describing: FCPGridTemplate.self):
            rootTemplate = FCPGridTemplate(obj: args["rootTemplate"] as! [String : Any])
            break
          case String(describing: FCPInformationTemplate.self):
            rootTemplate = FCPInformationTemplate(obj: args["rootTemplate"] as! [String : Any])
            break
          case String(describing: FCPPointOfInterestTemplate.self):
            rootTemplate = FCPPointOfInterestTemplate(obj: args["rootTemplate"] as! [String : Any])
            break
          case String(describing: FCPListTemplate.self):
            rootTemplate = FCPListTemplate(obj: args["rootTemplate"] as! [String : Any], templateType: FCPListTemplateTypes.DEFAULT)
            break
          default:
            result(false)
            return
      }

      SwiftFlutterCarplayPlugin.rootTemplate = rootTemplate!.get
      if !(SwiftFlutterCarplayPlugin.templateStack.isEmpty ?? true) {
          SwiftFlutterCarplayPlugin.templateStack[0] = rootTemplate!
      } else {
          SwiftFlutterCarplayPlugin.templateStack = [rootTemplate!]
      }
      SwiftFlutterCarplayPlugin.objcRootTemplate = rootTemplate!
      let animated = args["animated"] as! Bool
      SwiftFlutterCarplayPlugin.animated = animated
      result(true)
      break
    case FCPChannelTypes.forceUpdateRootTemplate:
      FlutterCarPlaySceneDelegate.forceUpdateRootTemplate()
      result(true)
      break
    case FCPChannelTypes.updateListTemplateSections:
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      let elementId = args["elementId"] as! String
      let sections = (args["sections"] as! Array<[String: Any]>).map {
        FCPListSection(obj: $0)
      }
      FlutterCarPlaySceneDelegate.updateListTemplateSections(elementId: elementId, sections: sections)
      result(true)
      break
    case FCPChannelTypes.updateTabBarTemplates:
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      let elementId = args["elementId"] as! String
      let templates = args["templates"] as! Array<[String: Any]>
      if templates.count > CPTabBarTemplate.maximumTabCount {
        result(FlutterError(code: "ERROR",
                            message: "CarPlay cannot have more than \(CPTabBarTemplate.maximumTabCount) templates on one screen.",
                            details: nil))
        return
      }
      FlutterCarPlaySceneDelegate.updateTabBarTemplates(elementId: elementId, templates: templates)
      result(true)
      break
    case FCPChannelTypes.updateListItem:
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      let elementId = args["_elementId"] as! String
      let text = args["text"] as? String
      let detailText = args["detailText"] as? String
      let image = args["image"] as? String
      let playbackProgress = args["playbackProgress"] as? CGFloat
      let isPlaying = args["isPlaying"] as? Bool
      let playingIndicatorLocation = args["playingIndicatorLocation"] as? String
      let accessoryType = args["accessoryType"] as? String
      SwiftFlutterCarplayPlugin.findItem(elementId: elementId, actionWhenFound: { item in
        item.update(text: text, detailText: detailText, image: image, playbackProgress: playbackProgress, isPlaying: isPlaying, playingIndicatorLocation: playingIndicatorLocation, accessoryType: accessoryType)
      })
      result(true)
      break
    case FCPChannelTypes.onListItemSelectedComplete:
      guard let args = call.arguments as? String else {
        result(false)
        return
      }
      SwiftFlutterCarplayPlugin.findItem(elementId: args, actionWhenFound: { item in
        item.stopHandler()
      })
      result(true)
      break
    case FCPChannelTypes.setAlert:
      guard self.objcPresentTemplate == nil else {
        result(FlutterError(code: "ERROR",
                            message: "CarPlay can only present one modal template at a time.",
                            details: nil))
        return
      }
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      let alertTemplate = FCPAlertTemplate.init(obj: args["rootTemplate"] as! [String : Any])
      self.objcPresentTemplate = alertTemplate
      let animated = args["animated"] as! Bool
      FlutterCarPlaySceneDelegate
        .presentTemplate(template: alertTemplate.get, animated: animated, onPresent: { completed in
          FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onPresentStateChanged,
                                           data: ["completed": completed])
      })
      result(true)
      break
    case FCPChannelTypes.setActionSheet:
      guard self.objcPresentTemplate == nil else {
        result(FlutterError(code: "ERROR",
                            message: "CarPlay can only present one modal template at a time.",
                            details: nil))
        return
      }
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      let actionSheetTemplate = FCPActionSheetTemplate.init(obj: args["rootTemplate"] as! [String : Any])
      self.objcPresentTemplate = actionSheetTemplate
      let animated = args["animated"] as! Bool
      FlutterCarPlaySceneDelegate.presentTemplate(template: actionSheetTemplate.get, animated: animated, onPresent: {_ in })
      result(true)
      break
    case FCPChannelTypes.popTemplate:
      guard let args = call.arguments as? [String : Any],
        SwiftFlutterCarplayPlugin.templateStack.count >= 2 else {
          result(false)
          return
      }
      for _ in 1...(args["count"] as! Int) {
        FlutterCarPlaySceneDelegate.pop(animated: args["animated"] as! Bool)
      }
      result(true)
      break
    case FCPChannelTypes.closePresent:
      guard let animated = call.arguments as? Bool else {
        result(false)
        return
      }
      FlutterCarPlaySceneDelegate.closePresent(animated: animated)
      self.objcPresentTemplate = nil
      result(true)
      break
    case FCPChannelTypes.showNowPlaying:
      guard let animated = call.arguments as? Bool else {
        result(false)
        return
      }
      let template = FCPSharedNowPlayingTemplate()

      let isCompleted = FlutterCarPlaySceneDelegate.pushIfNotExist(template: template.get as CPTemplate, animated: animated)
      if isCompleted {
        SwiftFlutterCarplayPlugin.templateStack.append(template)
        result(true)
      } else {
        result(false)
      }
      break
    case FCPChannelTypes.pushTemplate:
      guard let args = call.arguments as? [String : Any] else {
        result(false)
        return
      }
      var template: FCPRootTemplate?
      let animated = args["animated"] as! Bool
      switch args["runtimeType"] as! String {
        case String(describing: FCPGridTemplate.self):
          template = FCPGridTemplate(obj: args["template"] as! [String : Any])
          break
        case String(describing: FCPPointOfInterestTemplate.self):
          template = FCPPointOfInterestTemplate(obj: args["template"] as! [String : Any])
          break
        case String(describing: FCPInformationTemplate.self):
          template = FCPInformationTemplate(obj: args["template"] as! [String : Any])
          break
        case String(describing: FCPListTemplate.self):
          template = FCPListTemplate(obj: args["template"] as! [String : Any], templateType: FCPListTemplateTypes.DEFAULT)
          break
        default:
          result(false)
          return
      }

      let isCompleted = FlutterCarPlaySceneDelegate.push(template: template!.get, animated: animated)
      if isCompleted {
        SwiftFlutterCarplayPlugin.templateStack.append(template!)
        result(true)
      } else {
        result(false)
      }
      break
    case FCPChannelTypes.popToRootTemplate:
      guard let animated = call.arguments as? Bool,
        SwiftFlutterCarplayPlugin.templateStack.count >= 2 else {
          result(false)
          return
      }

      FlutterCarPlaySceneDelegate.popToRootTemplate(animated: animated)
      self.objcPresentTemplate = nil
      result(true)
      break
    default:
      result(false)
      break
    }
  }
  
  static func createEventChannel(event: String?) -> FlutterEventChannel {
    let eventChannel = FlutterEventChannel(name: makeFCPChannelId(event: event),
                                           binaryMessenger: SwiftFlutterCarplayPlugin.registrar!.messenger())
    return eventChannel
  }
  
  static func onCarplayConnectionChange(status: String) {
    FCPStreamHandlerPlugin.sendEvent(type: FCPChannelTypes.onCarplayConnectionChange,
                                     data: ["status": status])
  }
  
  static func findItem(elementId: String, actionWhenFound: (_ item: FCPListItem) -> Void) {
    var collected: [FCPListTemplate] = []

    for template in SwiftFlutterCarplayPlugin.templateStack {
       if let tabBar = template as? FCPTabBarTemplate {
              for child in tabBar.getTemplates() {
                  if let listTemplate = child as? FCPListTemplate {
                      collected.append(listTemplate)
                  }
              }
          } else if let list = template as? FCPListTemplate {
              collected.append(list)
          }
    }

    for t in collected {
      for s in t.getSections() {
        for i in s.getItems() {
          if (i.elementId == elementId) {
            actionWhenFound(i)
            return
          }
        }
      }
    }
    NSLog("FCP: Item not found with elementId: \(elementId)")
  }

  static public func getTemplateFromHistory(elementId: String) -> FCPRootTemplate? {
      for i in 0..<SwiftFlutterCarplayPlugin.templateStack.count {
          if SwiftFlutterCarplayPlugin.templateStack[i].elementId == elementId {
              return SwiftFlutterCarplayPlugin.templateStack[i]
          }

          if let tabBar = SwiftFlutterCarplayPlugin.templateStack[i] as? FCPTabBarTemplate {
              let subTemplates = tabBar.getTemplates()
              for j in 0..<subTemplates.count {
                  if subTemplates[j].elementId == elementId {
                      return subTemplates[j] as? FCPRootTemplate
                  }
              }
          }
      }
      return nil
  }
}
