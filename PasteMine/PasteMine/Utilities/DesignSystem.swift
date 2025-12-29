//
//  DesignSystem.swift
//  PasteMine
//
//  Design system for consistent UI across the app
//

import SwiftUI

/// Centralized design tokens for PasteMine
enum DesignSystem {

    // MARK: - Spacing (8px grid system)
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 4    // Small buttons, badges
        static let medium: CGFloat = 8   // Cards, search bar, settings sections
        static let large: CGFloat = 12   // Modals, large containers
    }

    // MARK: - Animation
    enum Animation {
        static let fast: Double = 0.15      // Micro-interactions (hover, press)
        static let standard: Double = 0.25  // Standard transitions
        static let slow: Double = 0.35      // Complex animations

        static func spring(duration: Double = 0.25) -> SwiftUI.Animation {
            .spring(duration: duration, bounce: 0.0)
        }

        static func easeOut(duration: Double = 0.15) -> SwiftUI.Animation {
            .easeOut(duration: duration)
        }

        static func easeInOut(duration: Double = 0.25) -> SwiftUI.Animation {
            .easeInOut(duration: duration)
        }
    }

    // MARK: - Shadow
    enum Shadow {
        struct Config {
            let color: Color
            let radius: CGFloat
            let y: CGFloat
        }

        static func subtle(isHovered: Bool = false) -> Config {
            Config(
                color: .black.opacity(isHovered ? 0.08 : 0.04),
                radius: isHovered ? 3 : 2,
                y: isHovered ? 1.5 : 1
            )
        }

        static func medium(isHovered: Bool = false) -> Config {
            Config(
                color: .black.opacity(isHovered ? 0.12 : 0.08),
                radius: isHovered ? 6 : 4,
                y: isHovered ? 2 : 1.5
            )
        }

        static func strong(isSelected: Bool = false) -> Config {
            Config(
                color: .black.opacity(isSelected ? 0.15 : 0.12),
                radius: isSelected ? 8 : 6,
                y: isSelected ? 3 : 2
            )
        }
    }
}

// MARK: - View Extensions
extension View {
    /// Apply shadow configuration
    func applyShadow(_ config: DesignSystem.Shadow.Config) -> some View {
        self.shadow(color: config.color, radius: config.radius, y: config.y)
    }

    /// Standard card background with material effect
    func cardBackground(isHovered: Bool = false) -> some View {
        self.background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
                    }
                    .applyShadow(DesignSystem.Shadow.medium(isHovered: isHovered))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(Color(NSColor.controlBackgroundColor))
            }
        }
    }
}
