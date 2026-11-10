// QELORYX — Platform/CarPlay
// CarPlaySceneDelegate.swift
//
// CarPlay entry point. Playback itself is driven by the shared audio engine;
// this scene only adapts CarPlay's template interface to the same commands.
// Compiles to nothing on platforms without CarPlay.

import Foundation

#if canImport(CarPlay) && canImport(UIKit)
import CarPlay
import UIKit

public final class QeloryxCarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        let nowPlayingTemplate = CPNowPlayingTemplate.shared
        let tabBar = CPTabBarTemplate(templates: [nowPlayingTemplate])
        interfaceController.setRootTemplate(tabBar, animated: true)
    }

    public func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        // Nothing to tear down: the engine is owned by the composition root.
    }
}
#endif
