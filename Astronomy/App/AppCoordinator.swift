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

        let standardAppearance = UINavigationBarAppearance()
        standardAppearance.configureWithOpaqueBackground()
        standardAppearance.backgroundColor = .systemBlue
        standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        // Transparent at scroll edge so the large title collapses when the table scrolls.
        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        navigationController.navigationBar.standardAppearance = standardAppearance
        navigationController.navigationBar.compactAppearance = standardAppearance
        navigationController.navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.navigationBar.tintColor = .white

        return navigationController
    }
}
