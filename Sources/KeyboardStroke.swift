import CoreGraphics

enum KeyboardStroke: Equatable {
    case key(CGKeyCode)
    case unicode([UniChar])

    init(character: Character) {
        switch character {
        case "\n", "\r": self = .key(36) // Return
        case "\t": self = .key(48)         // Tab
        default: self = .unicode(Array(String(character).utf16))
        }
    }
}
