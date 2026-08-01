import Foundation

/// Bundle'dan okunan sabitler. Adresler ve destek e-postası koda gömülmüyor
/// (§ `03` §2 madde 6); sürüm bilgisi de proje ayarlarının tek kopyası kalsın
/// diye burada okunuyor.
enum AppInfo {
    /// § `06` §1 satır 14: `mailto:` konusunda UserID ve sürüm hazır geliyor.
    static let supportEmail = string(for: "SupportEmail")

    /// § `06` §1 kimlik kartı: `Sürüm 1.0 (12)`.
    static var versionLine: String {
        let version = string(for: "CFBundleShortVersionString") ?? "1.0"
        let build = string(for: "CFBundleVersion") ?? "1"
        return "\(version) (\(build))"
    }

    /// Destek e-postasının gövdesi teşhis bilgisiyle hazır geliyor: kullanıcıdan
    /// UserID ve sürüm istemek yazışmayı bir tur uzatıyor.
    static func supportMailURL(subject: String, userID: String, locale: String) -> URL? {
        guard let supportEmail else { return nil }
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "\(subject) · \(userID)"),
            URLQueryItem(name: "body", value: "\n\n—\nUserID: \(userID)\n\(versionLine) · \(locale)"),
        ]
        return components.url
    }

    private static func string(for key: String) -> String? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.isEmpty,
            // Doldurulmamış build ayarı (`$(TERMS_URL)`) değer sayılmıyor.
            !value.hasPrefix("$")
        else { return nil }
        return value
    }
}

/// §03 §2 madde 6: `Koşullar` ve `Gizlilik` bağlantıları. Paywall ve Ayarlar
/// aynı adresleri gösteriyor.
enum LegalLinks {
    static var terms: URL? { url(for: "TermsURL") }
    static var privacy: URL? { url(for: "PrivacyURL") }

    private static func url(for key: String) -> URL? {
        guard
            let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
            !value.isEmpty, !value.hasPrefix("$")
        else { return nil }
        return URL(string: value)
    }
}
