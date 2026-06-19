//
//  SceneDelegate.swift
//  Astronomy
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard
            let windowScene = scene as? UIWindowScene,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
        else { return }

        window = appDelegate.appCoordinator.start(in: windowScene)

        if APIConfiguration.isUsingDemoKey {
            AppLogger.app.warning("Using NASA DEMO_KEY — rate limits apply. Copy Config/Secrets.xcconfig.example to Secrets.xcconfig.")
        }
    }
}
