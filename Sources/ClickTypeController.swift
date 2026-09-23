import AppKit
import ApplicationServices
import CoreGraphics

@MainActor
final class ClickTypeController {
    private(set) var statusMessage = "Click the icon to type clipboard text"
    private var pendingTexts: [String] = []
    private var typingTask: Task<Void, Never>?

    var hasAccessibilityAccess: Bool { AXIsProcessTrusted() }

    func typeClipboard(target: NSRunningApplication?) {
        guard hasAccessibilityAccess else {
            statusMessage = "Accessibility access required"
            requestAccessibilityAccess()
            return
        }

        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            statusMessage = "Clipboard has no plain text"
            return
        }

        guard let target else {
            statusMessage = "Select a text field in another app first"
            return
        }

        // Restore the app that owned the focused field before typing.
        Task { @MainActor [weak self] in
            guard (try? await Task.sleep(nanoseconds: 120_000_000)) != nil else { return }
            _ = target.activate(options: [])
            guard (try? await Task.sleep(nanoseconds: 80_000_000)) != nil else { return }
            self?.enqueue(text)
        }
    }

    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        statusMessage = hasAccessibilityAccess ? "Ready to type clipboard text" : "Grant access, then click the icon again"
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func enqueue(_ text: String) {
        pendingTexts.append(text)
        if typingTask == nil {
            typingTask = Task { @MainActor [weak self] in
                await self?.drainQueue()
            }
        }
    }

    private func drainQueue() async {
        defer { typingTask = nil }

        while !pendingTexts.isEmpty {
            let text = pendingTexts.removeFirst()
            for character in text {
                KeyboardTyper.post(character)
                // Pace events so target apps can process long or Unicode input.
                try? await Task.sleep(nanoseconds: 3_000_000)
            }
        }
        statusMessage = "Ready to type clipboard text"
    }
}

private enum KeyboardTyper {
    static func post(_ character: Character) {
        switch character {
        case "\n", "\r": postKey(code: 36) // Return
        case "\t": postKey(code: 48)        // Tab
        default:
            let units = Array(String(character).utf16)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else { return }
            units.withUnsafeBufferPointer { buffer in
                down.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
                up.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            }
            down.flags = []
            up.flags = []
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }

    private static func postKey(code: CGKeyCode) {
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else { return }
        down.flags = []
        up.flags = []
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
