import Foundation

/// A movie or episode the user has finished. Mirrors the Android `WatchedItem`
/// so it round-trips through `sync_push/pull_watched_items`.
struct WatchedItem: Codable, Identifiable, Hashable {
    let contentID: String
    let contentType: String
    let title: String
    let season: Int?
    let episode: Int?
    let watchedAt: Date

    /// Stable key: movie = contentID; episode = contentID|s|e.
    static func key(contentID: String, season: Int?, episode: Int?) -> String {
        if let season, let episode { return "\(contentID)|\(season)|\(episode)" }
        return contentID
    }

    var key: String { Self.key(contentID: contentID, season: season, episode: episode) }
    var id: String { key }
}

@MainActor
final class WatchedStore: ObservableObject {
    @Published private(set) var items: [String: WatchedItem] = [:]

    /// Fired after a local change so account sync can push. Suppressed while
    /// merging remote data.
    var onLocalChange: (() -> Void)?
    private var suppressChange = false

    private var profileID = 1
    private var storageKey: String {
        profileID == 1 ? "nuvio.watched.v1" : "nuvio.watched.v1.p\(profileID)"
    }

    init() { load() }

    func setProfile(_ id: Int) {
        guard id != profileID else { return }
        profileID = id
        suppressChange = true
        items = [:]
        load()
        suppressChange = false
    }

    // MARK: - Queries

    func isWatched(contentID: String, season: Int? = nil, episode: Int? = nil) -> Bool {
        items[WatchedItem.key(contentID: contentID, season: season, episode: episode)] != nil
    }

    /// Movie-level watched check.
    func isWatched(_ meta: MetaItem) -> Bool {
        !meta.isSeries && isWatched(contentID: meta.id)
    }

    // MARK: - Mutations

    func mark(meta: MetaItem, video: MetaVideo?) {
        let item = WatchedItem(
            contentID: meta.id,
            contentType: meta.type,
            title: video?.title ?? meta.name,
            season: video?.season,
            episode: video?.episode,
            watchedAt: Date()
        )
        set(item)
    }

    func toggleMovie(_ meta: MetaItem) {
        if isWatched(contentID: meta.id) {
            remove(contentID: meta.id, season: nil, episode: nil)
        } else {
            set(WatchedItem(
                contentID: meta.id, contentType: meta.type, title: meta.name,
                season: nil, episode: nil, watchedAt: Date()
            ))
        }
    }

    private func set(_ item: WatchedItem) {
        items[item.key] = item
        save()
        if !suppressChange { onLocalChange?() }
    }

    func remove(contentID: String, season: Int?, episode: Int?) {
        items.removeValue(forKey: WatchedItem.key(contentID: contentID, season: season, episode: episode))
        save()
        if !suppressChange { onLocalChange?() }
    }

    // MARK: - Sync bridge

    func allForSync() -> [WatchedItem] { Array(items.values) }

    func mergeRemote(_ remote: [WatchedItem]) {
        suppressChange = true
        defer { suppressChange = false }
        var changed = false
        for item in remote where items[item.key] == nil {
            items[item.key] = item
            changed = true
        }
        if changed { save() }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: WatchedItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
