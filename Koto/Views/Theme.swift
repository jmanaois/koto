import SwiftUI
import UIKit

/// LINE-inspired colors, with dark mode variants.
enum Theme {
    static let chatBackground = Color(light: 0x8FA9D3, dark: 0x1B1E25)
    static let userBubble = Color(light: 0x8DE055, dark: 0x5DBB4A)
    static let userBubbleText = Color.black
    static let botBubble = Color(light: 0xFFFFFF, dark: 0x2E323B)
    static let avatar = Color(light: 0x2BB673, dark: 0x2BB673)
    /// Timestamps, 既読 and names drawn directly on the chat background.
    static let metaText = Color(light: 0x2B3A55, dark: 0x9AA3B5)
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
