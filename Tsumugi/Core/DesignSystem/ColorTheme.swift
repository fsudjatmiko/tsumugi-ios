import SwiftUI

extension Color {
    // Exact Custom Palette
    static let tsumugiDustyDenim = Color(hex: 0x6290C3)
    static let tsumugiFrozenWater = Color(hex: 0xC2E7DA)
    static let tsumugiHoneydew   = Color(hex: 0xF1FFE7)
    static let tsumugiSpaceIndigo = Color(hex: 0x1A1B41)
    static let tsumugiChartreuse  = Color(hex: 0xBAFF29)

    // Dynamic Adaptive Colors (Light vs Dark)
    static let tsumugiBackground = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color.tsumugiSpaceIndigo) : UIColor(Color.tsumugiHoneydew)
    })
    
    static let tsumugiCardSurface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color.tsumugiSpaceIndigo.opacity(0.6)) : UIColor(Color.tsumugiFrozenWater.opacity(0.35))
    })

    // Hex Initializer Helper
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}
