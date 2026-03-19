import SwiftUI
import UIKit

extension Color {
    static let festPrimary = Color(red: 166/255, green: 47/255, blue: 54/255)

    static let festBackground = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return .systemBackground
        }
        return UIColor(red: 250/255, green: 245/255, blue: 235/255, alpha: 1)
    })

    static let festCardBackground = Color(uiColor: UIColor { trait in
        if trait.userInterfaceStyle == .dark {
            return .secondarySystemBackground
        }
        return .white
    })

    static let festChipBackground = Color(uiColor: .tertiarySystemFill)
}
