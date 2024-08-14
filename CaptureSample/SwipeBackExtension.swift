//
//  SwipeBackExtension.swift
//  CaptureSample
//
//  Created by ryan on 2024/8/14.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI

/// this extension enables swiping from left edge to navigate to previous page without navigation bar
/// ref: https://stackoverflow.com/questions/59921239/hide-navigation-bar-without-losing-swipe-back-gesture-in-swiftui

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
