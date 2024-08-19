//
//  verbarhythmApp.swift
//  verbarhythm
//
//  Created by Austin Condiff on 9/21/23.
//

import SwiftUI

@main
struct VerbarhythmApp: App {
    @StateObject var contentViewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(contentViewModel)
        }
    }
}
