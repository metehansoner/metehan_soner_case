import Foundation


enum AppInfo {

    static let supportEmail = string(for: "SupportEmail")


    static var versionLine: String {
        let version = string(for: "CFBundleShortVersionString") ?? "1.0"
        let build = string(for: "CFBundleVersion") ?? "1"
        return "\(version) (\(build))"
    }


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

            !value.hasPrefix("$")
        else { return nil }
        return value
    }
}


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
