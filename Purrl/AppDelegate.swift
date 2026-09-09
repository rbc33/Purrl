//
//  AppDelegate.swift
//  Purrl
//
//  Created by ric on 17/07/2026.
//

import Cocoa
import ServiceManagement
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var scrollEngine = ScrollHapticEngine()

    // Sparkle updater controller — starts the updater automatically
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // Tooth size presets — label is a localization key, resolved at menu build time
    private let toothPresets: [(key: String, value: CGFloat)] = [
        ("preset.fine", 4),
        ("preset.medium", 8),
        ("preset.coarse", 16),
        ("preset.veryCoarse", 28)
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

        // Touch updaterController once so Sparkle's lazy init runs and
        // the updater starts checking on its configured schedule.
        _ = updaterController

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Enable/disable toggle
        let toggleItem = NSMenuItem(
            title: scrollEngine.isEnabled
                ? NSLocalizedString("toggle.enabled", comment: "Menu item shown when scrolling haptics are on")
                : NSLocalizedString("toggle.disabled", comment: "Menu item shown when scrolling haptics are off"),
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Tooth size submenu
        let toothMenu = NSMenu()
        for preset in toothPresets {
            let localizedLabel = NSLocalizedString(preset.key, comment: "Tooth size preset label")
            let item = NSMenuItem(title: localizedLabel, action: #selector(selectTooth(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.value
            item.state = (scrollEngine.toothSize == preset.value) ? .on : .off
            toothMenu.addItem(item)
        }
        let toothParent = NSMenuItem(
            title: NSLocalizedString("menu.texture", comment: "Submenu title for tooth size options"),
            action: nil,
            keyEquivalent: ""
        )
        menu.setSubmenu(toothMenu, for: toothParent)
        menu.addItem(toothParent)

        menu.addItem(NSMenuItem.separator())

        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(
            title: launchAtLoginEnabled
                ? NSLocalizedString("menu.launchAtLoginEnabled", comment: "Menu item shown when launch at login is on")
                : NSLocalizedString("menu.launchAtLogin", comment: "Menu item shown when launch at login is off"),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        // Check for Updates now
        let checkUpdatesItem = NSMenuItem(
            title: NSLocalizedString("menu.checkForUpdates", comment: "Menu item to manually check for app updates"),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        checkUpdatesItem.isEnabled = updaterController.updater.canCheckForUpdates
        menu.addItem(checkUpdatesItem)

        // Automatic updates toggle
        let autoUpdateItem = NSMenuItem(
            title: updaterController.updater.automaticallyChecksForUpdates
                ? NSLocalizedString("menu.autoUpdateEnabled", comment: "Menu item shown when automatic update checks are on")
                : NSLocalizedString("menu.autoUpdate", comment: "Menu item shown when automatic update checks are off"),
            action: #selector(toggleAutomaticUpdates),
            keyEquivalent: ""
        )
        autoUpdateItem.target = self
        menu.addItem(autoUpdateItem)

        menu.addItem(NSMenuItem.separator())

        let permItem = NSMenuItem(
            title: NSLocalizedString("menu.checkPermission", comment: "Menu item to recheck Accessibility permission"),
            action: #selector(recheckPermission),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: "Menu item to quit the app"),
            action: #selector(quit),
            keyEquivalent: "q"
        )
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

    @objc func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    @objc func toggleAutomaticUpdates() {
        updaterController.updater.automaticallyChecksForUpdates.toggle()
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
