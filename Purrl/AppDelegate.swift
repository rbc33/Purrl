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

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private let toothPresets: [(key: String, value: CGFloat)] = [
        ("preset.fine", 4),
        ("preset.medium", 8),
        ("preset.coarse", 16),
        ("preset.veryCoarse", 28)
    ]

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

        _ = updaterController

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let toggleItem = NSMenuItem(
            title: scrollEngine.isEnabled
                ? NSLocalizedString("toggle.enabled", comment: "")
                : NSLocalizedString("toggle.disabled", comment: ""),
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        let toothMenu = NSMenu()
        for preset in toothPresets {
            let localizedLabel = NSLocalizedString(preset.key, comment: "")
            let item = NSMenuItem(title: localizedLabel, action: #selector(selectTooth(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.value
            item.state = (scrollEngine.toothSize == preset.value) ? .on : .off
            toothMenu.addItem(item)
        }
        let toothParent = NSMenuItem(
            title: NSLocalizedString("menu.texture", comment: ""),
            action: nil,
            keyEquivalent: ""
        )
        menu.setSubmenu(toothMenu, for: toothParent)
        menu.addItem(toothParent)

        let onlyScrollableItem = NSMenuItem(
            title: scrollEngine.onlyScrollableContent
                ? NSLocalizedString("menu.onlyScrollableEnabled", comment: "")
                : NSLocalizedString("menu.onlyScrollable", comment: ""),
            action: #selector(toggleOnlyScrollable),
            keyEquivalent: ""
        )
        onlyScrollableItem.target = self
        menu.addItem(onlyScrollableItem)

        menu.addItem(NSMenuItem.separator())

        let launchAtLoginItem = NSMenuItem(
            title: launchAtLoginEnabled
                ? NSLocalizedString("menu.launchAtLoginEnabled", comment: "")
                : NSLocalizedString("menu.launchAtLogin", comment: ""),
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(NSMenuItem.separator())

        let checkUpdatesItem = NSMenuItem(
            title: NSLocalizedString("menu.checkForUpdates", comment: ""),
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        checkUpdatesItem.isEnabled = updaterController.updater.canCheckForUpdates
        menu.addItem(checkUpdatesItem)

        let autoUpdateItem = NSMenuItem(
            title: updaterController.updater.automaticallyChecksForUpdates
                ? NSLocalizedString("menu.autoUpdateEnabled", comment: "")
                : NSLocalizedString("menu.autoUpdate", comment: ""),
            action: #selector(toggleAutomaticUpdates),
            keyEquivalent: ""
        )
        autoUpdateItem.target = self
        menu.addItem(autoUpdateItem)

        menu.addItem(NSMenuItem.separator())

        let permItem = NSMenuItem(
            title: NSLocalizedString("menu.checkPermission", comment: ""),
            action: #selector(recheckPermission),
            keyEquivalent: ""
        )
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(
            title: NSLocalizedString("menu.quit", comment: ""),
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

    @objc func toggleOnlyScrollable() {
        scrollEngine.onlyScrollableContent.toggle()
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
