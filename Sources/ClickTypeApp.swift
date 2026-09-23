import AppKit
import ServiceManagement
import SwiftUI

@main
struct ClickTypeApp: App {
    @NSApplicationDelegateAdaptor(ClickTypeAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class ClickTypeAppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let controller = ClickTypeController()
    private var lastTargetApplication: NSRunningApplication?
    private var loginStatusMessage: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        rememberTarget(NSWorkspace.shared.frontmostApplication)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "ClickType")
        button.toolTip = "Click to type clipboard text · Right-click for options"
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.option) == true {
            showOptions(under: sender)
        } else {
            typeClipboard()
        }
    }

    @objc private func applicationActivated(_ notification: Notification) {
        rememberTarget(notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)
    }

    private func rememberTarget(_ application: NSRunningApplication?) {
        guard let application,
              application.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        lastTargetApplication = application
    }

    private func typeClipboard() {
        let foreground = NSWorkspace.shared.frontmostApplication
        let target = foreground?.processIdentifier == ProcessInfo.processInfo.processIdentifier
            ? lastTargetApplication : foreground ?? lastTargetApplication
        controller.typeClipboard(target: target)
    }

    private func showOptions(under button: NSStatusBarButton) {
        let menu = NSMenu()

        let typeItem = NSMenuItem(title: "Type Clipboard Now", action: #selector(typeClipboardFromMenu), keyEquivalent: "")
        typeItem.target = self
        menu.addItem(typeItem)

        let status = NSMenuItem(title: controller.statusMessage, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let accessItem = NSMenuItem(title: controller.hasAccessibilityAccess ? "Accessibility Access Granted" : "Grant Accessibility Access…", action: #selector(requestAccessibility), keyEquivalent: "")
        accessItem.target = self
        accessItem.isEnabled = !controller.hasAccessibilityAccess
        menu.addItem(accessItem)

        let settingsItem = NSMenuItem(title: "Open Accessibility Settings…", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let loginItem = NSMenuItem(title: "Run at Login", action: #selector(toggleRunAtLogin), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        if SMAppService.mainApp.status == .requiresApproval {
            let approvalItem = NSMenuItem(title: "Approve in System Settings → Login Items", action: #selector(openLoginItemsSettings), keyEquivalent: "")
            approvalItem.target = self
            menu.addItem(approvalItem)
        }
        if let loginStatusMessage {
            let messageItem = NSMenuItem(title: loginStatusMessage, action: nil, keyEquivalent: "")
            messageItem.isEnabled = false
            menu.addItem(messageItem)
        }
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit ClickType", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: 0), in: button)
    }

    @objc private func typeClipboardFromMenu() { typeClipboard() }
    @objc private func requestAccessibility() { controller.requestAccessibilityAccess() }
    @objc private func openAccessibilitySettings() { controller.openAccessibilitySettings() }
    @objc private func toggleRunAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled || service.status == .requiresApproval {
                try service.unregister()
            } else {
                try service.register()
            }
            loginStatusMessage = service.status == .requiresApproval
                ? "Approval needed in System Settings"
                : nil
        } catch {
            loginStatusMessage = "Run at Login failed: \(error.localizedDescription)"
        }
    }
    @objc private func openLoginItemsSettings() { SMAppService.openSystemSettingsLoginItems() }
    @objc private func quit() { NSApp.terminate(nil) }
}
