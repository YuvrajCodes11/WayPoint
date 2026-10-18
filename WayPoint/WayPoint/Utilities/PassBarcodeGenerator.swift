//
//  PassBarcodeGenerator.swift
//  WayPoint
//
//  Phase 4: High-Resolution CoreImage Barcode & QR Code Generator
//

import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#endif

public enum PassBarcodeGenerator {
    private static let context = CIContext()

    public static func generateQRCode(from string: String, scale: CGFloat = 10.0) -> UIImage? {
        #if canImport(UIKit)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "H"

        guard let ciImage = filter.outputImage else { return nil }
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        if let cgImage = context.createCGImage(transformed, from: transformed.extent) {
            return UIImage(cgImage: cgImage)
        }
        #endif
        return nil
    }

    public static func generateCode128Barcode(from string: String, scaleX: CGFloat = 3.0, scaleY: CGFloat = 60.0) -> UIImage? {
        #if canImport(UIKit)
        guard let filter = CIFilter(name: "CICode128BarcodeGenerator") else { return nil }
        filter.setValue(Data(string.utf8), forKey: "inputMessage")

        guard let ciImage = filter.outputImage else { return nil }
        let transformed = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        if let cgImage = context.createCGImage(transformed, from: transformed.extent) {
            return UIImage(cgImage: cgImage)
        }
        #endif
        return nil
    }
}
