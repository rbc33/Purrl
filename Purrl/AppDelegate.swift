//
//  AppDelegate.swift
//  Purrl
//
//  Created by ric on 17/07/2026.
//

import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var scrollEngine = ScrollHapticEngine()

    // Tooth size presets
    private let toothPresets: [(label: String, value: CGFloat)] = [
        ("Fine (dense)", 4),
        ("Medium", 8),
        ("Coarse (spaced clicks)", 16),
        ("Extra coarse", 28)
    ]

    // Launch at Login state, backed by SMAppService
    private var launchAtLoginEnabled: Bool {
        get {
            SMAppService.mainApp.status == .enabled
        }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        checkAccessibilityPermission()
        scrollEngine.start()

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Enable/disable toggle
        let toggleItem = NSMenuItem(
            title: scrollEngine.isEnabled ? "Enabled ✓" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Tooth size submenu
        let toothMenu = NSMenu()
        for preset in toothPresets {
            let item = NSMenuItem(title: preset.label, action: #selector(selectTooth(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.value
            item.state = (scrollEngine.toothSize == preset.value) ? .on : .off
            toothMenu.addItem(item)
        }
        let toothParent = NSMenuItem(title: "Purr Texture", action: nil, keyEquivalent: "")
        menu.setSubmenu(toothMenu, for: toothParent)
        menu.addItem(toothParent)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(
            title: launchAtLoginEnabled ? "Launch at Login ✓" : "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let permItem = NSMenuItem(title: "Check Accessibility Permission", action: #selector(recheckPermission), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func toggleEnabled() {
        scrollEngine.isEnabled.toggle()
        rebuildMenu()
    }

    @objc func selectTooth(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? CGFloat else { return }
        scrollEngine.toothSize = value
        rebuildMenu()
    }

    @objc func toggleLaunchAtLogin() {
        launchAtLoginEnabled.toggle()
        rebuildMenu()
    }

    @objc func recheckPermission() {
        checkAccessibilityPermission()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)

        let symbolName = trusted ? "pawprint.fill" : "exclamationmark.triangle.fill"
        statusItem.button?.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Purrl")
    }
}
