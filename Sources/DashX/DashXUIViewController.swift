import Foundation
import UIKit

enum DashXScreenTracking {
    private static let swizzleOnce: Void = {
        swizzler(
            UIViewController.self,
            UIViewController.self,
            #selector(UIViewController.viewDidAppear(_:)),
            #selector(UIViewController.dashx_viewDidAppear(_:))
        )
    }()

    static func enable() {
        _ = swizzleOnce
    }

    static let ignoredClassNames: Set<String> = [
        "UINavigationController",
        "UITabBarController",
        "UISplitViewController",
        "UIPageViewController",
        "UIAlertController",
        "UIInputWindowController",
        "UICompatibilityInputViewController",
        "UIEditingOverlayViewController",
        "UISystemKeyboardDockController",
        "UIPredictionViewController",
        "UIApplicationRotationFollowingController",
        "UIApplicationRotationFollowingControllerNoTouches",
    ]

    /// Returns `nil` when the controller is not a screen. Hosting and system controllers
    /// have no meaningful class name, so they count only when titled.
    static func screenName(
        className: String,
        title: String?,
        navigationTitle: String?,
        isHostingController: Bool,
        isSystemClass: Bool = false
    ) -> String? {
        let name = stripModulePrefix(className)
        if name.isEmpty || name.hasPrefix("_") || ignoredClassNames.contains(name) {
            return nil
        }
        if let explicit = nonBlank(title) ?? nonBlank(navigationTitle) {
            return explicit
        }
        if isHostingController || isSystemClass {
            return nil
        }
        return name
    }

    static func screenName(for viewController: UIViewController) -> String? {
        if viewController is UINavigationController
            || viewController is UITabBarController
            || viewController is UISplitViewController
            || viewController is UIPageViewController
            || viewController is UIAlertController {
            return nil
        }
        let cls: AnyClass = type(of: viewController)
        return screenName(
            className: String(describing: cls),
            title: viewController.title,
            navigationTitle: viewController.navigationItem.title,
            isHostingController: isHostingController(cls),
            isSystemClass: isSystemClass(cls)
        )
    }

    private static func stripModulePrefix(_ className: String) -> String {
        let head = className.prefix { $0 != "<" }
        guard let dot = head.lastIndex(of: ".") else { return className }
        return String(className[className.index(after: dot)...])
    }

    private static func nonBlank(_ value: String?) -> String? {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return value
    }

    private static func isHostingController(_ cls: AnyClass) -> Bool {
        var current: AnyClass? = cls
        while let candidate = current, ObjectIdentifier(candidate) != ObjectIdentifier(UIViewController.self) {
            if NSStringFromClass(candidate).contains("UIHostingController") {
                return true
            }
            current = class_getSuperclass(candidate)
        }
        return false
    }

    // App controllers can live outside `Bundle.main` (embedded frameworks, pods), so only
    // OS-provided bundles count as system.
    static func isSystemClass(_ cls: AnyClass) -> Bool {
        Bundle(for: cls).bundlePath.contains("/System/Library/")
    }
}

extension UIViewController {
    @objc func dashx_viewDidAppear(_ animated: Bool) {
        // Swizzled: this calls the original viewDidAppear(_:).
        dashx_viewDidAppear(animated)
        if let name = DashXScreenTracking.screenName(for: self) {
            DashXClient.instance.screen(name)
        }
    }
}
