//
//  SplineWebContainer.swift
//  WayPoint
//

import SwiftUI
#if canImport(WebKit) && canImport(UIKit)
import WebKit
import UIKit

// MARK: - Persistent Singleton 3D Web View Manager with URL Caching

@MainActor
final class SplineWebViewManager {
    static let shared = SplineWebViewManager()
    private var webViews: [String: WKWebView] = [:]

    private init() {}

    func webView(for urlString: String) -> WKWebView {
        if let existing = webViews[urlString] {
            return existing
        }

        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let css = """
        a[href*="spline"], [class*="watermark"], [class*="logo"], [id*="spline"], #logo {
            display: none !important;
            visibility: hidden !important;
            opacity: 0 !important;
            pointer-events: none !important;
        }
        """
        let scriptSource = "var style = document.createElement('style'); style.innerHTML = '\(css.replacingOccurrences(of: "\n", with: " "))'; document.head.appendChild(style);"
        let script = WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(script)

        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.layer.isOpaque = false
        wv.backgroundColor = .clear
        wv.scrollView.backgroundColor = .clear
        wv.layer.backgroundColor = UIColor.clear.cgColor
        wv.scrollView.isScrollEnabled = false
        wv.isUserInteractionEnabled = false

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body, html { width: 100%; height: 100%; overflow: hidden; background: transparent; }
                iframe { width: 100vw; height: 100vh; border: 0; object-fit: cover; pointer-events: none; }
                a[href*="spline"], [class*="watermark"], [class*="logo"], [id*="spline"], #logo {
                    display: none !important;
                    visibility: hidden !important;
                    opacity: 0 !important;
                    pointer-events: none !important;
                }
            </style>
        </head>
        <body>
            <iframe src="\(urlString)"></iframe>
        </body>
        </html>
        """
        wv.loadHTMLString(htmlString, baseURL: URL(string: "https://my.spline.design"))
        webViews[urlString] = wv
        return wv
    }
}

// MARK: - Reusable SplineWebContainer Component

struct SplineWebContainer: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        return SplineWebViewManager.shared.webView(for: urlString)
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Leave completely empty so SwiftUI state passes do not invoke layout passes on WebKit
    }
}
#endif
