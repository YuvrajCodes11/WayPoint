//
//  WayPointProducts.swift
//  WayPoint
//
//  Module 3: Production StoreKit 2 Product Catalog Identifiers
//

import Foundation
import StoreKit

public enum WayPointProductIdentifier {
    public static let monthlyPro = "waypoint_pro_monthly"
    public static let annualPro = "com.waypoint.pro.annual"
    public static let lifetimePro = "waypoint_pro_lifetime"

    public static let all: Set<String> = [
        monthlyPro,
        annualPro,
        lifetimePro,
        "com.waypoint.pro.monthly",
        "com.waypoint.pro.lifetime"
    ]
}

public struct WayPointProductItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let displayPrice: String
    public let product: Product?

    public init(id: String, title: String, subtitle: String, displayPrice: String, product: Product? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.displayPrice = displayPrice
        self.product = product
    }
}
