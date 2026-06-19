//
//  AppDelegate.swift
//  Astronomy
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private(set) lazy var dependencies = AppDependencies()
    private(set) lazy var appCoordinator = AppCoordinator(dependencies: dependencies)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
    }
}
