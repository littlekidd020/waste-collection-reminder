import SwiftUI
import UIKit

enum AppTheme {
    static let buttonFill = Color(red: 0.06, green: 0.38, blue: 0.24)
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.4, green: 0.85, blue: 0.65, alpha: 1)
            : UIColor(red: 0.06, green: 0.38, blue: 0.24, alpha: 1)
    })
}
