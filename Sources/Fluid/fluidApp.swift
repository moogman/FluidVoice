//
//  fluidApp.swift
//  fluid
//
//  Created by Barathwaj Anandan on 7/30/25.
//

import SwiftUI
import AppKit
import ApplicationServices

@main
struct fluidApp: App {
    @StateObject private var menuBarManager = MenuBarManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showWhatsNew = false

    init() {
        // Note: App UI is designed with dark color scheme in mind
        // All gradients and effects are optimized for dark mode
        // AppDelegate handles initialization and permissions
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(menuBarManager)
                .preferredColorScheme(.dark) // Force dark mode to prevent UI issues
                .sheet(isPresented: $showWhatsNew) {
                    WhatsNewView()
                }
                .onAppear {
                    // Check if we should show what's new after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showWhatsNew = SettingsStore.shared.shouldShowWhatsNew()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowWhatsNew"))) { _ in
                    showWhatsNew = true
                }
        }
    }
}
