//
//  OfflineMapView.swift
//  WayPoint
//
//  Created for RevenueCat #Shipaton 2026
//  100% Offline Vector Transit Map View (Pure SwiftUI Canvas / Path Wrapper)
//

import SwiftUI

public struct OfflineMapView: View {
    @Bindable var router: GraphRouter = GraphRouter.shared
    
    public init(router: GraphRouter = GraphRouter.shared) {
        self.router = router
    }
    
    public var body: some View {
        OfflineTransitCanvasView()
    }
}

#Preview {
    OfflineMapView()
}
