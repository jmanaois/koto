import SwiftUI
import UIKit

/// The app's color theme, chosen in Settings. Read it in views with `@Environment(\.theme)`.
/// Green, red and the other semantic colors (right/wrong, saved) stay the same in every theme.
enum Theme: String, CaseIterable, Identifiable {
    /// LINE-inspired.
    case classic
    case blueGrey
    case lavender
    case salmon

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: "Classic"
        case .blueGrey: "Blue-grey"
        case .lavender: "Lavender"
        case .salmon: "Salmon pink"
        }
    }

    var chatBackground: Color {
        switch self {
        case .classic: Color(light: 0x8FA9D3, dark: 0x1B1E25)
        case .blueGrey: Color(light: 0xB7C3CF, dark: 0x1A1F25)
        case .lavender: Color(light: 0xD5CCEA, dark: 0x1D1A25)
        case .salmon: Color(light: 0xF5D3CA, dark: 0x251B1A)
        }
    }

    var userBubble: Color {
        switch self {
        case .classic: Color(light: 0x8DE055, dark: 0x5DBB4A)
        case .blueGrey: Color(light: 0x5B7590, dark: 0x4A6178)
        case .lavender: Color(light: 0x7D68B8, dark: 0x6A58A6)
        case .salmon: Color(light: 0xF29A85, dark: 0xB85D4C)
        }
    }

    var userBubbleText: Color {
        switch self {
        case .classic: .black
        case .salmon: Color(light: 0x000000, dark: 0xFFFFFF)
        case .blueGrey, .lavender: .white
        }
    }

    var botBubble: Color {
        switch self {
        case .classic: Color(light: 0xFFFFFF, dark: 0x2E323B)
        case .blueGrey: Color(light: 0xFFFFFF, dark: 0x2B3139)
        case .lavender: Color(light: 0xFFFFFF, dark: 0x2E2A39)
        case .salmon: Color(light: 0xFFFFFF, dark: 0x382C2A)
        }
    }

    /// Timestamps, 既読 and names drawn directly on the chat background.
    var metaText: Color {
        switch self {
        case .classic: Color(light: 0x2B3A55, dark: 0x9AA3B5)
        case .blueGrey: Color(light: 0x34424F, dark: 0x9AA6B2)
        case .lavender: Color(light: 0x463B66, dark: 0xA79FBD)
        case .salmon: Color(light: 0x6E3B30, dark: 0xBFA29C)
        }
    }

    /// Buttons, links and highlights across the app.
    var accent: Color {
        switch self {
        case .classic: Color(light: 0x2BB673, dark: 0x2BB673)
        case .blueGrey: Color(light: 0x52708E, dark: 0x8AA4BF)
        case .lavender: Color(light: 0x7D68B8, dark: 0xA996E0)
        case .salmon: Color(light: 0xD9654D, dark: 0xF08F7A)
        }
    }
}

extension EnvironmentValues {
    @Entry var theme: Theme = .classic
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
