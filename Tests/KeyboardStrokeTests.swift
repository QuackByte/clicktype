import XCTest
@testable import ClickType

final class KeyboardStrokeTests: XCTestCase {
    func testControlCharactersUsePhysicalKeys() {
        XCTAssertEqual(KeyboardStroke(character: "\n"), .key(36))
        XCTAssertEqual(KeyboardStroke(character: "\r"), .key(36))
        XCTAssertEqual(KeyboardStroke(character: "\t"), .key(48))
    }

    func testUnicodeCharactersPreserveAllUTF16Units() {
        XCTAssertEqual(KeyboardStroke(character: "A"), .unicode([65]))
        XCTAssertEqual(KeyboardStroke(character: "🦆"), .unicode(Array("🦆".utf16)))
        XCTAssertEqual(KeyboardStroke(character: "e\u{301}"), .unicode(Array("e\u{301}".utf16)))
    }
}
