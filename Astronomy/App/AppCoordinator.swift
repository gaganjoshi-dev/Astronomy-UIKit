//
//  AppCoordinator.swift
//  Astronomy
//

import UIKit

/// Handles app navigation and root UI setup.
final class AppCoordinator {

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    @discardableResult
    func start(in windowScene: UIWindowScene) -> UIWindow {
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        AppLogger.app.info("AppCoordinator started — root UI presented")
        return window
    }

    func makeRootViewController() -> UIViewController {
        let listViewController = AstronomyListViewController(
            repository: dependencies.astronomyRepository
        )
        return makeNavigationController(rootViewController: listViewController)
    }

    private func makeNavigationController(rootViewController: UIViewController) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: rootViewController)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.38, green: 0.64, blue: 0.96, alpha: 1.0)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = .white

        return navigationController
    }
}
