//
//  ColorExtensions.swift
//  PasteMine
//
//  Created for Liquid Glass design integration
//

import SwiftUI

extension Color {
    /// Semantic colors for Liquid Glass design
    static let glassBackground = Color.clear

    /// Shadow color helper with adjustable opacity
    static func shadowColor(opacity: Double = 0.1) -> Color {
        return .black.opacity(opacity)
    }
}

extension Animation {
    /// Standard Liquid Glass transition for material effects
    /// Duration: 0.25s with smooth curve
    static let glassTransition = Animation.smooth(duration: 0.25)

    /// Quick hover response animation
    /// Duration: 0.2s with smooth curve
    static let hoverTransition = Animation.smooth(duration: 0.2)
}
