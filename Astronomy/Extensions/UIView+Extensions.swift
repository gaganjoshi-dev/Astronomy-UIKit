//
//  UIView+Extensions.swift
//  Astronomy
//
//  Created by gagan joshi on 2024-10-12.
//

import UIKit

extension UIView {
    /// Adds a subview to this view while assuring it can work with Auto Layout
    func addAutolayoutSubview(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
    }

    /// Pins the given subview to this view edges. (Margins are ignored)
    func pinToEdges(_ subview: UIView) {
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            subview.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            subview.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    /// Centers the given view inside this view
    func centerInside(_ subview: UIView) {
        NSLayoutConstraint.activate([
            subview.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            subview.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
