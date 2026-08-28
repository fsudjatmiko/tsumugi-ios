import SwiftUI

public extension Color {
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
        trait.userInterfaceStyle == .dark ? UIColor(Color.tsumugiSpaceIndigo.opacity(0.85)) : UIColor.secondarySystemGroupedBackground
    })

    // Dynamic Text & Typography Tokens
    static let tsumugiTextPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? .white : UIColor(Color.tsumugiSpaceIndigo)
    })

    static let tsumugiTextSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.systemGray2 : UIColor(Color.tsumugiSpaceIndigo.opacity(0.7))
    })

    static let tsumugiSectionHeader = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(Color.tsumugiDustyDenim) : UIColor(Color.tsumugiSpaceIndigo)
    })

    static let tsumugiCardBorder = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : UIColor(Color.tsumugiFrozenWater).withAlphaComponent(0.5)
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
