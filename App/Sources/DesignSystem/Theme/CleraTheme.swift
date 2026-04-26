import SwiftUI

enum CleraColor {
    static let background = Color(hex: 0xF4F2EC)
    static let surface = Color(hex: 0xFFFFFF)
    static let elevatedSurface = Color.white.opacity(0.55)
    static let textPrimary = Color(hex: 0x1C1917)
    static let textSecondary = Color(hex: 0x635F5A)
    static let border = Color(hex: 0xD4D0C8)
    static let accent = Color(hex: 0x996C48)
    static let accentSoft = Color(hex: 0xF5EDE5)
    static let success = Color(hex: 0x99A744)
}

enum CleraSpacing {
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum CleraRadius {
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
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
    
    init(hex: String, alpha: Double = 1) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: int, alpha: alpha)
    }
}
