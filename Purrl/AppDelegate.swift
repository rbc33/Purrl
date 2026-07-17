//
//  AppDelegate.swift
//  Purrl
//
//  Created by ric on 17/07/2026.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var scrollEngine = ScrollHapticEngine()

    // Presets de tamaño de diente
    private let toothPresets: [(label: String, value: CGFloat)] = [
        ("Fino (denso)", 4),
        ("Medio", 8),
        ("Grueso (clic espaciado)", 16),
        ("Muy grueso", 28)
    ]

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        checkAccessibilityPermission()
        scrollEngine.start()

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Toggle activar/desactivar
        let toggleItem = NSMenuItem(
            title: scrollEngine.isEnabled ? "Activado ✓" : "Desactivado",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Submenú de tamaño de diente
        let toothMenu = NSMenu()
        for preset in toothPresets {
            let item = NSMenuItem(title: preset.label, action: #selector(selectTooth(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = preset.value
            item.state = (scrollEngine.toothSize == preset.value) ? .on : .off
            toothMenu.addItem(item)
        }
        let toothParent = NSMenuItem(title: "Textura del ronroneo", action: nil, keyEquivalent: "")
        menu.setSubmenu(toothMenu, for: toothParent)
        menu.addItem(toothParent)

        menu.addItem(NSMenuItem.separator())

        let permItem = NSMenuItem(title: "Comprobar permiso de Accesibilidad", action: #selector(recheckPermission), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)

        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(title: "Salir", action: #selector(quit), keyEquivalent: "q")
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

    @objc func recheckPermission() {
        checkAccessibilityPermission()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            statusItem.button?.title = "🐾⚠️"
        } else {
            statusItem.button?.title = "🐾"
        }
    }
}
