//
//  CrossCheckApp.swift
//  CrossCheck
//
//  Created by Wilson on 10/26/26.
//

import SwiftUI

@main
struct CrossCheckApp: App {
    @StateObject private var store = AuditStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
