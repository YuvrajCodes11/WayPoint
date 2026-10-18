//
//  OfflineImageStore.swift
//  WayPoint
//
//  Phase 1 & Phase 2: Offline Image Persistence & Apple HIG Asset Resolver
//

import SwiftUI
import Combine

/// Disk-backed image persistence engine & local asset fallback resolver for offline resilience
public final class OfflineImageStore: @unchecked Sendable {
    public static let shared = OfflineImageStore()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private var memoryCache = NSCache<NSString, UIImage>()

    private init() {
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesURL.appendingPathComponent("WaypointImageCache", isDirectory: true)
        createCacheDirectoryIfNeeded()
    }

    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }

    private func filename(for url: URL) -> String {
        let rawString = url.absoluteString
        let safeName = rawString.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: "_")
        let truncated = String(safeName.suffix(80))
        let hashValue = String(format: "%08x", rawString.hashValue)
        return "\(truncated)_\(hashValue).img"
    }

    private func fileURL(for url: URL) -> URL {
        return cacheDirectory.appendingPathComponent(filename(for: url))
    }

    /// Retrieve image from memory cache or disk storage
    public func imageFromCache(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        if let memoryImage = memoryCache.object(forKey: key) {
            return memoryImage
        }

        let path = fileURL(for: url).path
        if fileManager.fileExists(atPath: path),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
           let diskImage = UIImage(data: data) {
            memoryCache.setObject(diskImage, forKey: key)
            return diskImage
        }

        return nil
    }

    /// Fetch image from disk cache or network; writes bytes immediately to disk when online
    public func loadImage(from url: URL) async -> UIImage? {
        // 1. Check local disk & memory storage first
        if let cached = imageFromCache(for: url) {
            return cached
        }

        // 2. Fetch from network when online
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode),
                  let fetchedImage = UIImage(data: data) else {
                return nil
            }

            let diskURL = fileURL(for: url)
            try? data.write(to: diskURL, options: .atomic)
            memoryCache.setObject(fetchedImage, forKey: url.absoluteString as NSString)

            return fetchedImage
        } catch {
            print("[OfflineImageStore] Network fetch offline fallback (Airplane Mode active).")
            return nil
        }
    }

    /// Save image directly into cache
    public func storeImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        memoryCache.setObject(image, forKey: key)
        if let data = image.pngData() {
            let diskURL = fileURL(for: url)
            try? data.write(to: diskURL, options: .atomic)
        }
    }

    /// Clear all cached images from memory and disk
    public func clearDiskCache() {
        memoryCache.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

/// Drop-in SwiftUI component with disk cache and local bundled asset fallbacks
public struct OfflineCachedImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let fallbackSystemName: String
    let nodeName: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage? = nil
    @State private var isLoading: Bool = false

    public init(
        url: URL?,
        fallbackSystemName: String = "photo",
        nodeName: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.fallbackSystemName = fallbackSystemName
        self.nodeName = nodeName
        self.content = content
        self.placeholder = placeholder
    }

    public var body: some View {
        ZStack {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else if isLoading {
                placeholder()
            } else {
                fallbackView
            }
        }
        .task(id: url) {
            await loadImage()
        }
    }

    private func loadImage() async {
        // 1. Check if nodeName or URL maps to a local bundled asset
        if let assetName = assetNameForNode(), let bundled = UIImage(named: assetName) {
            self.uiImage = bundled
            return
        }

        guard let url = url else { return }

        // 2. Sync check on disk cache
        if let cached = OfflineImageStore.shared.imageFromCache(for: url) {
            self.uiImage = cached
            return
        }

        isLoading = true
        let fetched = await OfflineImageStore.shared.loadImage(from: url)
        isLoading = false
        if let fetched = fetched {
            self.uiImage = fetched
        }
    }

    private func assetNameForNode() -> String? {
        let node = (nodeName ?? url?.absoluteString ?? "").lowercased()
        if node.contains("shibuya") { return "station-shibuya" }
        if node.contains("big ben") || node.contains("big_ben") { return "station-bigben" }
        if node.contains("tokyo") { return "tokyo-metro" }
        if node.contains("london") { return "london-underground" }
        return nil
    }

    /// Primary Node HIG Graphic Fallback View
    @ViewBuilder
    private var fallbackView: some View {
        let node = (nodeName ?? url?.absoluteString ?? "").lowercased()

        if node.contains("tokyo") || node.contains("ginza") || node.contains("metro") {
            bundledNodeCard(icon: "tram.fill", label: "Tokyo Metro", color: .orange)
        } else if node.contains("london") || node.contains("bakerloo") || node.contains("tube") {
            bundledNodeCard(icon: "tram.circle.fill", label: "London Tube", color: .blue)
        } else if node.contains("shibuya") {
            bundledNodeCard(icon: "building.2.crop.circle.fill", label: "Shibuya Station", color: .purple)
        } else if node.contains("big ben") || node.contains("big_ben") || node.contains("westminster") {
            bundledNodeCard(icon: "clock.badge.checkmark.fill", label: "Big Ben Landmark", color: .amber)
        } else {
            ZStack {
                Color(uiColor: .tertiarySystemGroupedBackground)
                Image(systemName: fallbackSystemName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    private func bundledNodeCard(icon: String, label: String, color: Color) -> some View {
        ZStack {
            Color(uiColor: .secondarySystemGroupedBackground)
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(.caption2, design: .monospaced, weight: .medium))
                    .foregroundStyle(Color.secondary)
            }
            .padding(6)
        }
    }
}

extension Color {
    fileprivate static var amber: Color {
        Color(uiColor: .systemOrange)
    }
}

/// Convenience Initializer
extension OfflineCachedImage where Placeholder == AnyView {
    public init(
        url: URL?,
        fallbackSystemName: String = "photo",
        nodeName: String? = nil,
        @ViewBuilder content: @escaping (Image) -> Content
    ) {
        self.init(
            url: url,
            fallbackSystemName: fallbackSystemName,
            nodeName: nodeName,
            content: content,
            placeholder: {
                AnyView(
                    ZStack {
                        Color(uiColor: .secondarySystemGroupedBackground)
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                )
            }
        )
    }

    public init(url: URL?, fallbackSystemName: String = "photo", nodeName: String? = nil) where Content == Image {
        self.init(
            url: url,
            fallbackSystemName: fallbackSystemName,
            nodeName: nodeName,
            content: { img in img }
        )
    }
}
