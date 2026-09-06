//
//  GlobalAmbientBackground.swift
//  WayPoint
//

import SwiftUI
import WebKit

public struct GlobalAmbientBackground: View {
    @State private var splineLoaded = false

    public init() {}

    public var body: some View {
        ZStack {
            // 1. Instant Dark Base + Native Warmup Glow (Zero Loading Delay)
            Color(red: 0.04, green: 0.04, blue: 0.07)
                .ignoresSafeArea()

            // Native static ambient glow while Spline compiles WebGL shaders
            RadialGradient(
                colors: [Color.blue.opacity(0.18), Color.purple.opacity(0.14), Color.clear],
                center: .center,
                startRadius: 20,
                endRadius: 350
            )
            .ignoresSafeArea()

            // 2. Spline 3D Webview with Smooth Fade-in
            SplineWebView(url: URL(string: "https://my.spline.design/iridescenttorusanimation-34cvLNege0W70WxpEm6Aml6d/")!)
                .opacity(splineLoaded ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.6), value: splineLoaded)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onAppear {
            // Smoothly reveal Spline after WebKit initializes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                splineLoaded = true
            }
        }
    }
}

struct SplineWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isUserInteractionEnabled = false
        
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body { width: 100%; height: 100%; overflow: hidden; background: transparent; }
                iframe { width: 100%; height: 100%; border: none; background: transparent; }
            </style>
        </head>
        <body>
            <iframe src="\(url.absoluteString)" frameborder="0" width="100%" height="100%"></iframe>
        </body>
        </html>
        """
        
        webView.loadHTMLString(htmlString, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Leave intentionally empty to prevent reloading during state updates
    }
}

#Preview {
    GlobalAmbientBackground()
}
