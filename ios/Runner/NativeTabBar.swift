import Flutter
import UIKit

// The bottom tabs as a real UITabBar laid over the Flutter view, so on iOS 26
// they get Liquid Glass. Flutter says which tabs to show and which one is
// selected; a tap goes back to it as a "select" call. The Library page's
// floating pill row is drawn here too, as a glass capsule above the tabs.
final class NativeTabBar: NSObject, UITabBarDelegate, UIGestureRecognizerDelegate {
  static let shared = NativeTabBar()

  private var channel: FlutterMethodChannel?
  private var tabBar: UITabBar?
  private var ids: [String] = []
  private var shownLayout: [String] = []
  private var hidden = false

  private var holding = false
  private var holdEndedAt: Date?
  private var selectedBeforeHold: UITabBarItem?
  // The tab whose page is really showing: the one Flutter last set, or the
  // last real tap. The bar's own highlight can run ahead of it during a hold.
  private var shownItem: UITabBarItem?

  private var pill: UIVisualEffectView?
  private var pillStack: UIStackView?
  private var pillIndicator: UIView?
  private var pillIndicatorConstraints: [NSLayoutConstraint] = []
  private var pillButtons: [UIButton] = []
  private var pillLabels: [String] = []
  private var pillTint: UIColor = .systemBlue
  private var pillLayout = ""
  private var pillSelected = -1
  private var pillHidden = false

  private var toast: UIVisualEffectView?
  private var toastLabel: UILabel?
  private var toastIcon: UIImageView?
  private var toastId = -1
  private var toastTimer: DispatchWorkItem?

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.absorb.native_tabs", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "gone", message: "The tab bar is gone.", details: nil))
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "isSupported":
        if #available(iOS 26.0, *) {
          result(true)
        } else {
          result(false)
        }
      case "show":
        self.show(args, result: result)
      case "setHidden":
        self.setHidden(args["hidden"] as? Bool ?? false)
        result(nil)
      case "remove":
        self.removePill()
        self.tabBar?.removeFromSuperview()
        self.tabBar = nil
        self.ids = []
        self.shownLayout = []
        self.hidden = false
        result(nil)
      case "pillShow":
        self.showPill(args, result: result)
      case "pillSetHidden":
        self.setPillHidden(args["hidden"] as? Bool ?? false)
        result(nil)
      case "pillRemove":
        self.removePill()
        result(nil)
      case "toastShow":
        self.showToast(args, result: result)
      case "toastDismiss":
        if (args["id"] as? Int ?? -1) == self.toastId { self.dismissToast() }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  // tabs: [{ id, title, icon }] where icon is an SF Symbol name.
  // Answers with the bar's height, so Flutter can leave room for it.
  private func show(_ args: [String: Any], result: @escaping FlutterResult) {
    guard let host = flutterView() else {
      result(FlutterError(code: "no_view", message: "The app's view isn't ready yet.", details: nil))
      return
    }
    let tabs = args["tabs"] as? [[String: Any]] ?? []
    let bar = tabBar ?? makeBar(in: host)
    if bar.superview !== host {
      bar.removeFromSuperview()
      attach(bar, to: host)
    }
    host.bringSubviewToFront(bar)

    // Only rebuild the items when they changed: replacing them on every
    // update would cut off the bar's own selection animation.
    let layout = tabs.map { "\($0["id"] ?? "")|\($0["title"] ?? "")|\($0["icon"] ?? "")" }
    if layout != shownLayout {
      shownLayout = layout
      ids = tabs.compactMap { $0["id"] as? String }
      bar.items = tabs.enumerated().map { index, tab in
        let symbol = tab["icon"] as? String ?? "circle"
        let item = UITabBarItem(title: tab["title"] as? String ?? "",
                                image: UIImage(systemName: symbol), tag: index)
        item.selectedImage = UIImage(systemName: symbol + ".fill") ?? UIImage(systemName: symbol)
        return item
      }
    }
    if let selected = args["selected"] as? String,
       let index = ids.firstIndex(of: selected),
       let items = bar.items, index < items.count {
      shownItem = items[index]
      if bar.selectedItem !== items[index] { bar.selectedItem = items[index] }
    }
    if let tint = args["tint"] as? NSNumber {
      bar.tintColor = color(argb: tint.uint32Value)
    }
    if let dark = args["dark"] as? Bool {
      bar.overrideUserInterfaceStyle = dark ? .dark : .light
    }
    bar.isHidden = hidden
    bar.alpha = hidden ? 0 : 1
    host.layoutIfNeeded()
    result(Double(bar.frame.height))
  }

  // Hidden while another page or a sheet covers the tabs, since the bar sits
  // above everything Flutter draws.
  private func setHidden(_ hide: Bool) {
    hidden = hide
    guard let bar = tabBar else { return }
    if !hide { bar.isHidden = false }
    UIView.animate(withDuration: 0.2, animations: {
      bar.alpha = hide ? 0 : 1
    }, completion: { _ in
      bar.isHidden = self.hidden
    })
  }

  private func makeBar(in host: UIView) -> UITabBar {
    let bar = UITabBar()
    bar.delegate = self
    bar.translatesAutoresizingMaskIntoConstraints = false
    let hold = UILongPressGestureRecognizer(target: self, action: #selector(barHeld(_:)))
    hold.delegate = self
    // The bar slides its glass to a tab as soon as a finger lands on it, so a
    // hold on another tab moved the glass there without going there. Touches
    // reach the bar only once this has ruled out a hold: a tap or a drag
    // still lands, a hold never does.
    hold.delaysTouchesBegan = true
    bar.addGestureRecognizer(hold)
    attach(bar, to: host)
    tabBar = bar
    return bar
  }

  private func attach(_ bar: UITabBar, to host: UIView) {
    host.addSubview(bar)
    NSLayoutConstraint.activate([
      bar.leadingAnchor.constraint(equalTo: host.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: host.trailingAnchor),
      bar.bottomAnchor.constraint(equalTo: host.bottomAnchor),
    ])
  }

  // The phone window's Flutter view. CarPlay has its own scene, so only a
  // window whose root is the Flutter controller counts.
  private func flutterView() -> UIView? {
    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene else { continue }
      for window in windowScene.windows {
        if let controller = window.rootViewController as? FlutterViewController {
          return controller.view
        }
      }
    }
    return nil
  }

  private func color(argb: UInt32) -> UIColor {
    UIColor(red: CGFloat((argb >> 16) & 0xFF) / 255,
            green: CGFloat((argb >> 8) & 0xFF) / 255,
            blue: CGFloat(argb & 0xFF) / 255,
            alpha: CGFloat((argb >> 24) & 0xFF) / 255)
  }

  func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    // Letting go after a hold also counts as a tap on that tab. The hold
    // already ran its shortcut, so put the selection back and say nothing.
    let justHeld = holdEndedAt.map { Date().timeIntervalSince($0) < 0.6 } ?? false
    if holding || justHeld {
      if let before = selectedBeforeHold { tabBar.selectedItem = before }
      return
    }
    guard item.tag >= 0, item.tag < ids.count else { return }
    shownItem = item
    channel?.invokeMethod("select", arguments: ["id": ids[item.tag]])
  }

  // MARK: Holding a tab

  @objc private func barHeld(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      guard let bar = tabBar, !ids.isEmpty else { return }
      holding = true
      selectedBeforeHold = shownItem ?? bar.selectedItem
      let index = tabIndex(at: gesture.location(in: bar).x, in: bar)
      channel?.invokeMethod("hold", arguments: ["id": ids[index]])
    case .ended, .cancelled, .failed:
      holding = false
      holdEndedAt = Date()
      restoreAfterHold()
    default:
      break
    }
  }

  // On iOS 26 the bar picks a tab with gesture handlers of its own, which a
  // hold can't hold back and which don't always report it, so the tab that
  // was held could stay lit while its page never opened. Put the tab that
  // was showing back now, and again once the bar's own slide has run.
  private func restoreAfterHold() {
    guard let before = selectedBeforeHold else { return }
    let put = { [weak self] in
      guard let bar = self?.tabBar, self?.holding == false,
            bar.items?.contains(where: { $0 === before }) == true else { return }
      if bar.selectedItem !== before { bar.selectedItem = before }
    }
    put()
    for delay in [0.15, 0.45] {
      DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: put)
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    true
  }

  // UITabBar doesn't say where its items are, so this goes by the buttons it
  // lays out. If their count doesn't match the tabs, the span they cover is
  // split evenly instead.
  private func tabIndex(at x: CGFloat, in bar: UITabBar) -> Int {
    let frames = itemControls(in: bar).map { $0.convert($0.bounds, to: bar) }
    var centers = frames.map { $0.midX }.sorted()
    if centers.count != ids.count {
      let minX = frames.map { $0.minX }.min() ?? bar.bounds.minX
      let maxX = frames.map { $0.maxX }.max() ?? bar.bounds.maxX
      let slot = (maxX - minX) / CGFloat(ids.count)
      centers = (0..<ids.count).map { minX + (CGFloat($0) + 0.5) * slot }
    }
    var best = 0
    for (index, center) in centers.enumerated() where abs(center - x) < abs(centers[best] - x) {
      best = index
    }
    return best
  }

  private func itemControls(in view: UIView) -> [UIView] {
    var found: [UIView] = []
    for sub in view.subviews {
      if sub is UIControl, !sub.isHidden, sub.bounds.width > 0 {
        found.append(sub)
      } else {
        found += itemControls(in: sub)
      }
    }
    return found
  }

  // MARK: Library pill row

  // labels: the pills in order. selected: the active one. Tapping it again
  // opens sorting, which Flutter handles.
  private func showPill(_ args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      result(FlutterError(code: "unsupported", message: "Needs iOS 26.", details: nil))
      return
    }
    guard let host = flutterView() else {
      result(FlutterError(code: "no_view", message: "The app's view isn't ready yet.", details: nil))
      return
    }
    let labels = args["labels"] as? [String] ?? []
    let selected = args["selected"] as? Int ?? 0
    let tintValue = (args["tint"] as? NSNumber)?.uint32Value ?? 0xFF007AFF
    let view = pill ?? makePill(in: host)
    host.bringSubviewToFront(view)
    if let dark = args["dark"] as? Bool {
      view.overrideUserInterfaceStyle = dark ? .dark : .light
    }

    // The row is only rebuilt when its pills change. A new selection just
    // slides the highlight, so the row keeps its width and nothing jumps.
    let layout = labels.joined(separator: "|") + "#\(tintValue)"
    let rebuilt = layout != pillLayout
    if rebuilt {
      pillLayout = layout
      pillLabels = labels
      pillTint = color(argb: tintValue)
      pillSelected = -1
      rebuildPill()
      view.transform = .identity
      host.layoutIfNeeded()
      view.layer.cornerRadius = view.bounds.height / 2
      // Shrink the whole row when it is wider than the screen allows.
      let room = host.bounds.width - 32
      if view.bounds.width > room, view.bounds.width > 0, room > 0 {
        let scale = room / view.bounds.width
        view.transform = CGAffineTransform(scaleX: scale, y: scale)
      }
    }
    if selected != pillSelected {
      selectPill(selected, animated: !rebuilt)
    }
    view.isHidden = pillHidden
    view.alpha = pillHidden ? 0 : 1
    result(nil)
  }

  @available(iOS 26.0, *)
  private func makePill(in host: UIView) -> UIVisualEffectView {
    let effect = UIGlassEffect(style: .regular)
    effect.isInteractive = true
    let view = UIVisualEffectView(effect: effect)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true

    let indicator = UIView()
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.isUserInteractionEnabled = false
    indicator.layer.cornerCurve = .continuous
    indicator.isHidden = true
    view.contentView.addSubview(indicator)

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 0
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.contentView.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor, constant: 4),
      stack.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor, constant: -4),
      stack.topAnchor.constraint(equalTo: view.contentView.topAnchor, constant: 4),
      stack.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor, constant: -4),
    ])

    host.addSubview(view)
    var constraints = [view.centerXAnchor.constraint(equalTo: host.centerXAnchor)]
    if let bar = tabBar, bar.superview === host {
      constraints.append(view.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -8))
    } else {
      constraints.append(view.bottomAnchor.constraint(
        equalTo: host.safeAreaLayoutGuide.bottomAnchor, constant: -12))
    }
    NSLayoutConstraint.activate(constraints)

    pill = view
    pillStack = stack
    pillIndicator = indicator
    return view
  }

  private func pillFont(active: Bool) -> UIFont {
    UIFont.systemFont(ofSize: 13, weight: active ? .bold : .medium)
  }

  private func pillConfig(label: String, active: Bool) -> UIButton.Configuration {
    var attributes = AttributeContainer()
    attributes.font = pillFont(active: active)
    var config = UIButton.Configuration.plain()
    config.attributedTitle = AttributedString(label, attributes: attributes)
    config.baseForegroundColor = active ? pillTint : UIColor.secondaryLabel
    config.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 0, bottom: 9, trailing: 0)
    config.background.backgroundColor = .clear
    return config
  }

  private func rebuildPill() {
    guard let stack = pillStack else { return }
    for old in stack.arrangedSubviews {
      stack.removeArrangedSubview(old)
      old.removeFromSuperview()
    }
    pillButtons = []
    NSLayoutConstraint.deactivate(pillIndicatorConstraints)
    pillIndicatorConstraints = []
    pillIndicator?.isHidden = true
    pillIndicator?.backgroundColor = pillTint.withAlphaComponent(0.2)
    for (index, label) in pillLabels.enumerated() {
      let button = UIButton(configuration: pillConfig(label: label, active: false))
      button.tag = index
      button.addTarget(self, action: #selector(pillTapped(_:)), for: .touchUpInside)
      // Sized for the bold title, so the pill is the same width whether or
      // not it is the active one.
      let width = (label as NSString).size(withAttributes: [.font: pillFont(active: true)]).width
      button.widthAnchor.constraint(equalToConstant: width.rounded(.up) + 28).isActive = true
      stack.addArrangedSubview(button)
      pillButtons.append(button)
    }
  }

  private func selectPill(_ index: Int, animated: Bool) {
    guard let view = pill, let indicator = pillIndicator,
          index >= 0, index < pillButtons.count else { return }
    pillSelected = index
    for (i, button) in pillButtons.enumerated() {
      button.configuration = pillConfig(label: pillLabels[i], active: i == index)
    }
    let target = pillButtons[index]
    NSLayoutConstraint.deactivate(pillIndicatorConstraints)
    pillIndicatorConstraints = [
      indicator.leadingAnchor.constraint(equalTo: target.leadingAnchor),
      indicator.trailingAnchor.constraint(equalTo: target.trailingAnchor),
      indicator.topAnchor.constraint(equalTo: target.topAnchor),
      indicator.bottomAnchor.constraint(equalTo: target.bottomAnchor),
    ]
    NSLayoutConstraint.activate(pillIndicatorConstraints)
    let wasHidden = indicator.isHidden
    indicator.isHidden = false
    if animated && !wasHidden {
      UIView.animate(
        withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.3,
        options: [.allowUserInteraction, .beginFromCurrentState],
        animations: { view.contentView.layoutIfNeeded() })
    } else {
      view.contentView.layoutIfNeeded()
    }
    indicator.layer.cornerRadius = target.bounds.height / 2
  }

  @objc private func pillTapped(_ sender: UIButton) {
    channel?.invokeMethod("pillSelect", arguments: [
      "index": sender.tag,
      "reselect": sender.tag == pillSelected,
    ])
  }

  private func setPillHidden(_ hide: Bool) {
    pillHidden = hide
    guard let view = pill else { return }
    if !hide { view.isHidden = false }
    UIView.animate(withDuration: 0.2, animations: {
      view.alpha = hide ? 0 : 1
    }, completion: { _ in
      view.isHidden = self.pillHidden
    })
  }

  private func removePill() {
    pill?.removeFromSuperview()
    pill = nil
    pillStack = nil
    pillIndicator = nil
    pillIndicatorConstraints = []
    pillButtons = []
    pillLabels = []
    pillLayout = ""
    pillSelected = -1
    pillHidden = false
  }

  // MARK: Toasts

  // One toast at a time, as a glass capsule above the tabs. Showing the id
  // that is already up changes its text in place. `seconds` is left out for
  // a toast that stays until it is dismissed.
  private func showToast(_ args: [String: Any], result: @escaping FlutterResult) {
    guard #available(iOS 26.0, *) else {
      result(FlutterError(code: "unsupported", message: "Needs iOS 26.", details: nil))
      return
    }
    guard let host = flutterView() else {
      result(FlutterError(code: "no_view", message: "The app's view isn't ready yet.", details: nil))
      return
    }
    let id = args["id"] as? Int ?? 0
    let message = args["message"] as? String ?? ""
    let icon = (args["icon"] as? FlutterStandardTypedData).flatMap {
      UIImage(data: $0.data, scale: 3)
    }
    let tappable = args["tappable"] as? Bool ?? false

    let isNew = toast == nil || id != toastId
    if isNew {
      toast?.removeFromSuperview()
      toast = makeToast(in: host)
    }
    guard let view = toast else {
      result(FlutterError(code: "no_view", message: "The toast could not be made.", details: nil))
      return
    }
    toastId = id
    toastLabel?.text = message
    toastIcon?.image = icon
    toastIcon?.isHidden = icon == nil
    view.isUserInteractionEnabled = tappable
    if let dark = args["dark"] as? Bool {
      view.overrideUserInterfaceStyle = dark ? .dark : .light
    }
    host.bringSubviewToFront(view)
    host.layoutIfNeeded()
    view.layer.cornerRadius = min(view.bounds.height / 2, 24)

    if isNew {
      view.alpha = 0
      view.transform = CGAffineTransform(translationX: 0, y: 12)
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut], animations: {
        view.alpha = 1
        view.transform = .identity
      })
    }

    toastTimer?.cancel()
    toastTimer = nil
    if let seconds = args["seconds"] as? NSNumber {
      let work = DispatchWorkItem { [weak self] in
        guard let self = self, self.toastId == id else { return }
        self.dismissToast()
      }
      toastTimer = work
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds.doubleValue, execute: work)
    }
    result(nil)
  }

  @available(iOS 26.0, *)
  private func makeToast(in host: UIView) -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIGlassEffect(style: .regular))
    view.translatesAutoresizingMaskIntoConstraints = false
    view.clipsToBounds = true
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toastTapped)))

    let icon = UIImageView()
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    let label = UILabel()
    label.font = .systemFont(ofSize: 13, weight: .medium)
    label.textColor = .label
    label.numberOfLines = 3
    label.textAlignment = .natural

    let stack = UIStackView(arrangedSubviews: [icon, label])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.contentView.addSubview(stack)
    host.addSubview(view)

    let resting = view.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -100)
    resting.priority = .defaultHigh
    NSLayoutConstraint.activate([
      icon.widthAnchor.constraint(equalToConstant: 18),
      icon.heightAnchor.constraint(equalToConstant: 18),
      stack.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: view.contentView.topAnchor, constant: 10),
      stack.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor, constant: -10),
      view.centerXAnchor.constraint(equalTo: host.centerXAnchor),
      view.widthAnchor.constraint(lessThanOrEqualTo: host.widthAnchor, constant: -64),
      view.widthAnchor.constraint(lessThanOrEqualToConstant: 420),
      resting,
      // Stay clear of the keyboard when it is up.
      view.bottomAnchor.constraint(lessThanOrEqualTo: host.keyboardLayoutGuide.topAnchor, constant: -16),
    ])

    toastLabel = label
    toastIcon = icon
    return view
  }

  @objc private func toastTapped() {
    let id = toastId
    dismissToast()
    channel?.invokeMethod("toastTap", arguments: ["id": id])
  }

  private func dismissToast() {
    toastTimer?.cancel()
    toastTimer = nil
    guard let view = toast else { return }
    toast = nil
    toastLabel = nil
    toastIcon = nil
    toastId = -1
    UIView.animate(withDuration: 0.2, animations: {
      view.alpha = 0
    }, completion: { _ in
      view.removeFromSuperview()
    })
  }
}
