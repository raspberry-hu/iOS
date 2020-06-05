import Foundation

struct Font: Codable {
    typealias FontName = String

    let size: CGFloat
    let weight: FontWeight
    var name: FontName {
        switch (weight, size) {
        case (.italic, _):
            return "SFUIText-Italic"
        case (_, 20...):
            return "SFUIDisplay-\(weight)"
        default:
            return "SFUIText-\(weight)"
        }
    }
}

extension Font {

    /// Size 17, Semibold
    static let header = Font(size: 17, weight: .semibold)

    /// Size 12.5, Semibold
    static let caption1 = Font(size: 12.5, weight: .semibold)

    /// Size 12.5, Regular
    static let caption2 = Font(size: 12.5, weight: .regular)
}

func uiFont(from font: Font) -> UIFont? {
    return UIFont(name: font.name, size: font.size)
}

enum FontWeight: String, Codable {
    case italic = "Italic"
    case light = "Light"
    case medium = "Medium"
    case regular = "Regular"
    case semibold = "Semibold"
}
