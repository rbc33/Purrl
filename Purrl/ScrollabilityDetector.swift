//
//  ScrollabilityDetector.swift
//  Purrl
//
//  Created by Purrl on 08/08/2026.
//

import Cocoa
import ApplicationServices

class ScrollabilityDetector {
    private var cachedLocation: CGPoint = .zero
    private var cachedIsScrollable: Bool = true
    private var cachedTime: TimeInterval = 0
    private let cacheDuration: TimeInterval = 0.04 // 40ms cache for instant responsiveness
    private let cacheDistanceThreshold: CGFloat = 1.0 // 1 point movement threshold

    /// Returns whether the UI element under the current mouse cursor is in a scrollable view or region.
    func isScrollableAtCurrentCursor() -> Bool {
        guard let cgEvent = CGEvent(source: nil) else { return true }
        let point = cgEvent.location
        let now = ProcessInfo.processInfo.systemUptime

        // Use cached decision if cursor location hasn't moved and cache is fresh
        let distance = hypot(point.x - cachedLocation.x, point.y - cachedLocation.y)
        if distance < cacheDistanceThreshold && (now - cachedTime) < cacheDuration {
            return cachedIsScrollable
        }

        let isScrollable = checkScrollability(at: point)

        cachedLocation = point
        cachedTime = now
        cachedIsScrollable = isScrollable
        return isScrollable
    }

    private func checkScrollability(at point: CGPoint) -> Bool {
        // If process is not trusted for Accessibility, default to true
        guard AXIsProcessTrusted() else { return true }

        let systemWide = AXUIElementCreateSystemWide()
        var elementRef: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, Float(point.x), Float(point.y), &elementRef)

        guard result == .success, let startElement = elementRef else {
            return true
        }

        var current: AXUIElement? = startElement
        var depth = 0
        let maxDepth = 15

        // Recognized scrollable container roles in macOS Accessibility
        let scrollableRoles: Set<String> = [
            kAXScrollAreaRole,
            "AXScrollView",
            "AXWebArea",
            kAXTableRole,
            kAXOutlineRole,
            kAXListRole,
            kAXTextAreaRole,
            kAXScrollBarRole,
            "AXGrid",
            "AXBrowser"
        ]

        while let elem = current, depth < maxDepth {
            // 1. Inspect role, subrole, and title
            var roleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(elem, kAXRoleAttribute as CFString, &roleRef)
            let roleString = (roleRef as? String) ?? ""

            var subroleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(elem, kAXSubroleAttribute as CFString, &subroleRef)
            let subroleString = (subroleRef as? String) ?? ""

            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(elem, kAXTitleAttribute as CFString, &titleRef)
            let titleString = (titleRef as? String) ?? ""

            // Non-scrollable system regions (Menu bar, Status bar, Dock)
            if roleString == kAXMenuBarRole || roleString == "AXMenuExtra" || roleString == kAXMenuRole || roleString == kAXMenuItemRole || subroleString == "AXDockItem" {
                return false
            }

            // Finder Desktop background check
            if subroleString == "AXDesktopArea" || (roleString == kAXScrollAreaRole && titleString == "Desktop") {
                return false
            }

            // If ancestor is a valid scrollable container
            if scrollableRoles.contains(roleString) {
                return true
            }

            // Inspect parent element up the hierarchy
            var parentRef: CFTypeRef?
            let parentResult = AXUIElementCopyAttributeValue(elem, kAXParentAttribute as CFString, &parentRef)
            if parentResult == .success, let parent = parentRef {
                current = (parent as! AXUIElement)
            } else {
                current = nil
            }
            depth += 1
        }

        return false
    }
}
