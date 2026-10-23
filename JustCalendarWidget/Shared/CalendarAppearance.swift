import CoreText
import SwiftUI

/// Palette and display typography adapted from maseaaao.tv/packages/design.
/// Keep the calendar light, like the source identity, regardless of desktop wallpaper.
enum CalendarAppearance {
    static let brand = Color(red: 22 / 255, green: 22 / 255, blue: 217 / 255)
    static let surface = Color(red: 244 / 255, green: 243 / 255, blue: 236 / 255)
    static let field = Color(red: 1, green: 254 / 255, blue: 248 / 255)
    static let text = Color(red: 32 / 255, green: 32 / 255, blue: 30 / 255)
    static let muted = Color(red: 96 / 255, green: 96 / 255, blue: 90 / 255)
    static let border = Color(red: 210 / 255, green: 209 / 255, blue: 201 / 255)
    static let accentSoft = Color(red: 232 / 255, green: 232 / 255, blue: 252 / 255)

    static func displayFont(size: CGFloat) -> Font {
        .custom("Unbounded", size: size).weight(.semibold)
    }

    static func registerFonts(in bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "Unbounded", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
