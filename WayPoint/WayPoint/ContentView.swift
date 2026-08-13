//
//  ContentView.swift
//  WayPoint
//
//  Created by Yuvraj on 12/08/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        HomeView()
            .environment(SubscriptionManager.shared)
    }
}

#Preview {
    ContentView()
}
