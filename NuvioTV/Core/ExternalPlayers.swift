import UIKit

/// Detection + handoff for external player apps installed on the Apple TV.
/// Uses ONLY each app's public URL scheme (the standard "Open in <app>"
/// pattern) — no private APIs, no code from those apps.
enum ExternalPlayers {
    /// Infuse registers `infuse://`. `canOpenURL` needs the scheme listed in
    /// Info.plist's `LSApplicationQueriesSchemes`.
    static var isInfuseInstalled: Bool {
        guard let url = URL(string: "infuse://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    /// Hand a stream URL to Infuse via its documented x-callback-url play action.
    static func openInInfuse(urlString: String) {
        let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryValue) ?? urlString
        guard let url = URL(string: "infuse://x-callback-url/play?url=\(encoded)") else { return }
        UIApplication.shared.open(url)
    }
}

private extension CharacterSet {
    /// URL-query-VALUE safe (RFC 3986 unreserved only) so an inner URL is fully
    /// percent-encoded and survives as one parameter.
    static let urlQueryValue: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()
}
