// QELORYX — App
// AppDelegate.swift
//
// UIKit delegate bridge for the SwiftUI app lifecycle. Kept deliberately
// thin: only behaviour that genuinely belongs to UIApplicationDelegate lives
// here — cold-launch optimisation, background-task registration and playback
// restoration are all in `AppLifecycle`, and the dependency graph is built by
// `AppCompositionRoot`.

#if canImport(UIKit)
import UIKit

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Intentionally empty: `AppLifecycle.didLaunch()` runs in `QeloryxApp.init`,
        // which SwiftUI evaluates before the first scene connects, so doing the
        // same work here would double-count the launch measurement.
        true
    }
}
#endif
