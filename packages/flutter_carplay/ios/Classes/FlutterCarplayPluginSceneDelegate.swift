//
//  FlutterCarPlayPluginsSceneDelegate.swift
//  flutter_carplay
//
//  Created by Oğuzhan Atalay on 21.08.2021.
//

import CarPlay

extension CPTemplate {
  private static var elementIdKey: UInt8 = 0

  var elementId: String? {
    get {
      return objc_getAssociatedObject(self, &CPTemplate.elementIdKey) as? String
    }
    set {
      objc_setAssociatedObject(self, &CPTemplate.elementIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

@available(iOS 14.0, *)
@objc(FlutterCarPlaySceneDelegate)
class FlutterCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPInterfaceControllerDelegate {
  static private var interfaceController: CPInterfaceController?

  static var isConnected: Bool {
    return interfaceController != nil
  }

  static public func forceUpdateRootTemplate() {
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate
    let animated = SwiftFlutterCarplayPlugin.animated

    self.interfaceController?.setRootTemplate(rootTemplate!, animated: animated)
  }

  // https://developer.apple.com/documentation/carplay/cplisttemplate/updatesections(_:)
  static public func updateListTemplateSections(elementId: String, sections: [FCPListSection]) {
    guard let templateFromHistory = SwiftFlutterCarplayPlugin.getTemplateFromHistory(elementId: elementId) as? FCPListTemplate  else {
      NSLog("FlutterCarPlaySceneDelegate - updateListTemplateSections: Template from history with elementId \(elementId) not found.")
      return
    }

    templateFromHistory.updateSections(sections: sections)
  }

  // https://developer.apple.com/documentation/carplay/cptabbartemplate/updatetemplates(_:)
  static public func updateTabBarTemplates(elementId: String, templates: Array<[String: Any]>) {
    guard let templateFromHistory = SwiftFlutterCarplayPlugin.getTemplateFromHistory(elementId: elementId) as? FCPTabBarTemplate  else {
        NSLog("FlutterCarPlaySceneDelegate - updateTabBarTemplates: TabBar template from history with elementId \(elementId) not found.")
        return
    }

    templateFromHistory.updateTemplates(newTemplatesData: templates)
  }

  // Fired when just before the carplay become active
  func sceneDidBecomeActive(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
  }
  
  // Fired when carplay entered background
  func sceneDidEnterBackground(_ scene: UIScene) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.background)
  }
  
  static public func pop(animated: Bool) {
    self.interfaceController?.popTemplate(animated: animated)
  }
  
  static public func popToRootTemplate(animated: Bool) {
    self.interfaceController?.popToRootTemplate(animated: animated)
  }
  
  static public func push(template: CPTemplate, animated: Bool) -> Bool {
    guard let interfaceController = self.interfaceController else { return false }
    guard interfaceController.rootTemplate != nil else { return false }

    interfaceController.pushTemplate(template, animated: animated)
    return true
  }

  static public func pushIfNotExist(template: CPTemplate, animated: Bool) -> Bool {
    guard let interfaceController = self.interfaceController else { return false }
    guard interfaceController.rootTemplate != nil else { return false }

    let isAlreadyPushed = interfaceController.templates.contains { $0 === template }
    let isTopSameInstance = interfaceController.topTemplate === template

    if !isAlreadyPushed && !isTopSameInstance {
        interfaceController.pushTemplate(template, animated: animated)
        return true
    }
    return false
  }

  func templateDidDisappear(_ template: CPTemplate, animated: Bool) {
      guard let interfaceController = FlutterCarPlaySceneDelegate.interfaceController else { return }

      let currentTemplates = interfaceController.templates

      SwiftFlutterCarplayPlugin.templateStack.removeAll { stackTemplate in
          if !currentTemplates.contains(where: { $0.elementId == stackTemplate.elementId }) {
              SwiftFlutterCarplayPlugin.sendOnScreenBackButtonPressed(elementId: stackTemplate.elementId)
              return true
          }
          return false
      }
  }

  static public func closePresent(animated: Bool) {
    self.interfaceController?.dismissTemplate(animated: animated)
  }

  static public func presentTemplate(template: CPTemplate, animated: Bool,
                                     onPresent: @escaping (_ completed: Bool) -> Void) {
    self.interfaceController?.presentTemplate(template, animated: animated, completion: { completed, error in
      guard error != nil else {
        onPresent(false)
        return
      }
      onPresent(completed)
    })
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
    FlutterCarPlaySceneDelegate.interfaceController = interfaceController
    interfaceController.delegate = self
    
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.connected)
    let rootTemplate = SwiftFlutterCarplayPlugin.rootTemplate

    if rootTemplate != nil {
      FlutterCarPlaySceneDelegate.interfaceController?.setRootTemplate(rootTemplate!, animated: SwiftFlutterCarplayPlugin.animated, completion: nil)
    }
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

    interfaceController.delegate = nil
    FlutterCarPlaySceneDelegate.interfaceController = nil
  }
  
  func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
    SwiftFlutterCarplayPlugin.onCarplayConnectionChange(status: FCPConnectionTypes.disconnected)

    interfaceController.delegate = nil
    FlutterCarPlaySceneDelegate.interfaceController = nil
  }
}
