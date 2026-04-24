import SwiftUI

enum CleraColor {
    static let background = Color(hex: 0xFFFFFF)
    static let surface = Color(hex: 0xF7F7F5)
    static let elevatedSurface = Color.white.opacity(0.88)
    static let textPrimary = Color(hex: 0x171717)
    static let textSecondary = Color(hex: 0x6B6B6B)
    static let border = Color(hex: 0xE5E5E5)
    static let accent = Color(hex: 0x2563EB)
    static let accentSoft = Color(hex: 0xEAF1FF)
    static let success = Color(hex: 0xD7E9DF)
}

enum CleraSpacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum CleraRadius {
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let pill: CGFloat = 999
}

extension Color {
    init(hex: UInt64, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

