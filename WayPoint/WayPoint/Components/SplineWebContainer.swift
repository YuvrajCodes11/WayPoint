//
// SplineWebContainer.swift
// WayPoint
//

import SwiftUI
import WebKit

public struct SplineWebContainer: UIViewRepresentable {
    public let embedURL: String

    public init(embedURL: String = "https://my.spline.design/iridescenttorusanimation-34cvLNege0W70WxpEm6Aml6d/") {
        self.embedURL = embedURL
    }

    public init(urlString: String) {
        self.embedURL = urlString
    }

    public func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                html, body {
                    width: 100vw;
                    height: 100vh;
                    overflow: hidden !important;
                    background: transparent !important;
                    position: fixed;
                    top: 0;
                    left: 0;
                }
                iframe, canvas, spline-viewer {
                    width: 100vw !important;
                    height: 100vh !important;
                    position: fixed !important;
                    top: 0 !important;
                    left: 0 !important;
                    object-fit: cover !important;
                    transform: scale(1.45) !important;
                    transform-origin: center center !important;
                }
                #logo, a[href*="spline.design"], [class*="watermark"], .spline-watermark, #watermark {
                    display: none !important;
                    opacity: 0 !important;
                    visibility: hidden !important;
                    pointer-events: none !important;
                }
            </style>
        </head>
        <body>
            <iframe src="\(embedURL)" frameborder="0" width="100%" height="100%" scrolling="no"></iframe>
        </body>
        </html>
        """

        webView.loadHTMLString(htmlString, baseURL: URL(string: "https://my.spline.design"))
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}
}
