//
//  PurrlApp.swift
//  Purrl
//
//  Created by ric on 17/07/2026.
//

import SwiftUI

@main
struct PurrlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
