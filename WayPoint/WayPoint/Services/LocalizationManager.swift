//
//  LocalizationManager.swift
//  WayPoint
//
//  Task 2.3: String Catalog & Localization Architecture
//

import Foundation
import SwiftUI

public struct LocalizationManager {

    /// Dictionary fallback map mirroring Localizable.xcstrings for multi-language test execution and runtime resolution.
    private static let localizedDict: [String: [String: String]] = [
        "Dashboard": [
            "en": "Dashboard", "ja": "ダッシュボード", "es": "Panel Principal", "fr": "Tableau de Bord", "de": "Dashboard"
        ],
        "Radar": [
            "en": "Radar", "ja": "マップレーダー", "es": "Radar", "fr": "Radar", "de": "Radar"
        ],
        "Pass Vault": [
            "en": "Pass Vault", "ja": "デジタルパス", "es": "Bóveda de Pases", "fr": "Coffre de Pass", "de": "Pass-Tresor"
        ],
        "Settings": [
            "en": "Settings", "ja": "設定", "es": "Ajustes", "fr": "Réglages", "de": "Einstellungen"
        ],
        "Intelligent Re-balance": [
            "en": "Intelligent Re-balance", "ja": "AI自動リバランス", "es": "Reequilibrio Inteligente", "fr": "Rééquilibrage Intelligent", "de": "Intelligenter Neuausgleich"
        ],
        "Start Live": [
            "en": "Start Live", "ja": "ライブ開始", "es": "Iniciar Live", "fr": "Démarrer Live", "de": "Live Starten"
        ],
        "Stop Live": [
            "en": "Stop Live", "ja": "ライブ停止", "es": "Detener Live", "fr": "Arrêter Live", "de": "Live Stoppen"
        ],
        "Apply Changes": [
            "en": "Apply Changes", "ja": "変更を適用", "es": "Aplicar Cambios", "fr": "Appliquer les Modifications", "de": "Änderungen Anwenden"
        ],
        "Undo Re-balance": [
            "en": "Undo Re-balance", "ja": "元に戻す", "es": "Deshacer Reequilibrio", "fr": "Annuler le Rééquilibrage", "de": "Neuausgleich Rückgängig"
        ],
        "Weather Defense": [
            "en": "Weather Defense", "ja": "全天候防衛", "es": "Defensa Meteorológica", "fr": "Défense Météo", "de": "Wetterschutz"
        ],
        "Transit Delay": [
            "en": "Transit Delay", "ja": "交通遅延", "es": "Retraso de Tránsito", "fr": "Retard de Transit", "de": "Transitverzögerung"
        ],
        "Venue Closure": [
            "en": "Venue Closure", "ja": "施設休業", "es": "Cierre del Lugar", "fr": "Fermeture du Lieu", "de": "Veranstaltungsort Schließung"
        ],
        "Daily Budget": [
            "en": "Daily Budget", "ja": "日別予算", "es": "Presupuesto Diario", "fr": "Budget Quotidien", "de": "Tagesbudget"
        ],
        "Spent": [
            "en": "Spent", "ja": "支出済", "es": "Gastado", "fr": "Dépensé", "de": "Ausgegeben"
        ],
        "Remaining": [
            "en": "Remaining", "ja": "残高", "es": "Restante", "fr": "Restant", "de": "Verbleibend"
        ],
        "Daily Limit": [
            "en": "Daily Limit", "ja": "上限額", "es": "Límite Diario", "fr": "Limite Quotidienne", "de": "Tageslimit"
        ],
        "Scan Receipt": [
            "en": "Scan Receipt", "ja": "レシートスキャン", "es": "Escanear Recibo", "fr": "Scanner le Reçu", "de": "Beleg Scannen"
        ],
        "All Passes": [
            "en": "All Passes", "ja": "すべてのパス", "es": "Todos los Pases", "fr": "Tous les Pass", "de": "Alle Pässe"
        ],
        "Flights": [
            "en": "Flights", "ja": "フライト", "es": "Vuelos", "fr": "Vols", "de": "Flüge"
        ],
        "Hotels": [
            "en": "Hotels", "ja": "ホテル", "es": "Hoteles", "fr": "Hôtels", "de": "Hotels"
        ],
        "Activities": [
            "en": "Activities", "ja": "アクティビティ", "es": "Actividades", "fr": "Activités", "de": "Aktivitäten"
        ],
        "Add to Apple Wallet": [
            "en": "Add to Apple Wallet", "ja": "Apple Walletに追加", "es": "Añadir a Apple Wallet", "fr": "Ajouter à Apple Wallet", "de": "Zu Apple Wallet Hinzufügen"
        ],
        "Scan Pass": [
            "en": "Scan Pass", "ja": "パスをスキャン", "es": "Escanear Pase", "fr": "Scanner le Pass", "de": "Pass Scannen"
        ],
        "Confirm": [
            "en": "Confirm", "ja": "確認", "es": "Confirmar", "fr": "Confirmer", "de": "Bestätigen"
        ],
        "Cancel": [
            "en": "Cancel", "ja": "キャンセル", "es": "Cancelar", "fr": "Annuler", "de": "Abbrechen"
        ],
        "Done": [
            "en": "Done", "ja": "完了", "es": "Hecho", "fr": "Terminé", "de": "Fertig"
        ],
        "Error": [
            "en": "Error", "ja": "エラー", "es": "Error", "fr": "Erreur", "de": "Fehler"
        ],
        "Retry": [
            "en": "Retry", "ja": "再試行", "es": "Reintentar", "fr": "Réessayer", "de": "Wiederholen"
        ],
        "Camera Access Required": [
            "en": "Camera Access Required", "ja": "カメラへのアクセスが必要です", "es": "Acceso a la Cámara Requerido", "fr": "Accès Appareil Photo Requis", "de": "Kamerazugriff Erforderlich"
        ],
        "Open Settings": [
            "en": "Open Settings", "ja": "設定を開く", "es": "Abrir Ajustes", "fr": "Ouvrir les Réglages", "de": "Einstellungen Öffnen"
        ],
        "Day %lld": [
            "en": "Day %lld", "ja": "%lld日目", "es": "Día %lld", "fr": "Jour %lld", "de": "Tag %lld"
        ],
        "%@ spent of %@": [
            "en": "%@ spent of %@", "ja": "%@ / %@", "es": "%@ gastado de %@", "fr": "%@ dépensé sur %@", "de": "%@ ausgegeben von %@"
        ]
    ]

    /// Programmatically resolves a localized string key for a specific language code ("en", "ja", "es", "fr", "de").
    public static func string(forKey key: String, languageCode: String = "en") -> String {
        if let langMap = localizedDict[key], let val = langMap[languageCode] {
            return val
        }
        return key
    }

    /// Formats a localized string containing dynamic arguments (e.g. Day %lld or %@ spent of %@).
    public static func formattedString(forKey key: String, languageCode: String = "en", arguments: [CVarArg]) -> String {
        let template = string(forKey: key, languageCode: languageCode)
        return String(format: template, arguments: arguments)
    }
}
