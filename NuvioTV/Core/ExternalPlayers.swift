import UIKit

/// One external player app the Apple TV might have installed, addressable via
/// its public URL scheme (the standard "Open in <app>" pattern) — no private
/// APIs, no code from those apps.
struct ExternalPlayer: Identifiable, Equatable {
    let id: String
    let name: String
    /// Scheme probed with canOpenURL (must be in LSApplicationQueriesSchemes).
    let probeScheme: String
    /// Builds the handoff URL for a direct stream link.
    let makeURL: (String) -> URL?

    var isInstalled: Bool {
        guard let url = URL(string: "\(probeScheme)://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func open(streamURL: String) {
        guard let url = makeURL(streamURL) else { return }
        UIApplication.shared.open(url)
    }

    static func == (lhs: ExternalPlayer, rhs: ExternalPlayer) -> Bool { lhs.id == rhs.id }
}

/// Detection + handoff for external player apps installed on the Apple TV.
enum ExternalPlayers {
    /// Every player we know how to hand a stream to on tvOS. Detection is a
    /// canOpenURL probe, so only apps actually installed show up in Settings.
    static let catalog: [ExternalPlayer] = [
        ExternalPlayer(
            id: "infuse", name: "Infuse", probeScheme: "infuse",
            makeURL: { stream in
                URL(string: "infuse://x-callback-url/play?url=\(encode(stream))")
            }
        ),
        ExternalPlayer(
            id: "vlc", name: "VLC", probeScheme: "vlc-x-callback",
            makeURL: { stream in
                URL(string: "vlc-x-callback://x-callback-url/stream?url=\(encode(stream))")
            }
        ),
        ExternalPlayer(
            id: "nplayer", name: "nPlayer", probeScheme: "nplayer-http",
            makeURL: { stream in
                // nPlayer's documented form: prefix the URL's scheme with
                // "nplayer-" (http → nplayer-http).
                URL(string: "nplayer-\(stream)")
            }
        ),
        ExternalPlayer(
            id: "vidhub", name: "VidHub", probeScheme: "open-vidhub",
            makeURL: { stream in
                URL(string: "open-vidhub://x-callback-url/open?url=\(encode(stream))")
            }
        ),
    ]

    /// The players actually installed on this Apple TV, catalog order.
    static var installed: [ExternalPlayer] {
        catalog.filter(\.isInstalled)
    }

    static func player(id: String) -> ExternalPlayer? {
        catalog.first { $0.id == id }
    }

    // Legacy convenience (Sources-page "Play in Infuse" context action).
    static var isInfuseInstalled: Bool {
        player(id: "infuse")?.isInstalled ?? false
    }

    static func openInInfuse(urlString: String) {
        player(id: "infuse")?.open(streamURL: urlString)
    }

    private static func encode(_ urlString: String) -> String {
        urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryValue) ?? urlString
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
