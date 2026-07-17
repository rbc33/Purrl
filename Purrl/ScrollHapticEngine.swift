//
//  ScrolHapticEngine.swift
//  Purrl
//
//  Created by ric on 17/07/2026.
//

import Cocoa

class ScrollHapticEngine {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var accumulatedDistance: CGFloat = 0
    private var lastToothTime: TimeInterval = 0
    private let minToothInterval: TimeInterval = 0.012

    // Configurable, con persistencia
    var toothSize: CGFloat {
        get { UserDefaults.standard.object(forKey: "toothSize") as? CGFloat ?? 8.0 }
        set { UserDefaults.standard.set(newValue, forKey: "toothSize") }
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "isEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isEnabled") }
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScroll(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScroll(event)
            return event
        }
    }

    func stop() {
        if let m = globalMonitor { NSEvent.removeMonitor(m) }
        if let m = localMonitor { NSEvent.removeMonitor(m) }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handleScroll(_ event: NSEvent) {
        guard isEnabled else { return }
        let delta = abs(event.scrollingDeltaY)
        guard delta > 0 else { return }

        accumulatedDistance += delta
        while accumulatedDistance >= toothSize {
            fireTooth()
            accumulatedDistance -= toothSize
        }
    }

    private func fireTooth() {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastToothTime >= minToothInterval else { return }
        lastToothTime = now
        NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
    }
}
