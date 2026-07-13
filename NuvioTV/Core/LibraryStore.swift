import Foundation

/// A movie/show the user saved to their library. Mirrors the Android
/// `SavedLibraryItem` so it round-trips through `sync_push/pull_library`.
struct SavedLibraryItem: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let name: String
    let poster: String?
    let posterShape: String
    let background: String?
    let description: String?
    let releaseInfo: String?
    let imdbRating: Double?
    let genres: [String]
    let addonBaseURL: String?
    let addedAt: Date

    /// Stable storage key (a title can exist as both movie and series).
    var key: String { "\(type)|\(id)" }

    init(
        id: String, type: String, name: String,
        poster: String? = nil, posterShape: String = "POSTER",
        background: String? = nil, description: String? = nil,
        releaseInfo: String? = nil, imdbRating: Double? = nil,
        genres: [String] = [], addonBaseURL: String? = nil,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.poster = poster
        self.posterShape = posterShape
        self.background = background
        self.description = description
        self.releaseInfo = releaseInfo
        self.imdbRating = imdbRating
        self.genres = genres
        self.addonBaseURL = addonBaseURL
        self.addedAt = addedAt
    }

    init(meta: MetaItem) {
        self.init(
            id: meta.id,
            type: meta.type,
            name: meta.name,
            poster: meta.poster,
            posterShape: "POSTER",
            background: meta.background,
            description: meta.description,
            releaseInfo: meta.releaseInfo,
            imdbRating: meta.imdbRating.flatMap { Double($0) },
            genres: meta.genres ?? [],
            addonBaseURL: nil,
            addedAt: Date()
        )
    }

    /// Reconstruct a `MetaItem` good enough to open the detail page.
    var metaItem: MetaItem {
        MetaItem(
            id: id, type: type, name: name,
            poster: poster, background: background,
            description: description, releaseInfo: releaseInfo,
            imdbRating: imdbRating.map { String(format: "%.1f", $0) },
            genres: genres.isEmpty ? nil : genres
        )
    }
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var items: [String: SavedLibraryItem] = [:]

    /// Called after a local change so account sync can push. Suppressed while
    /// merging remote data.
    var onLocalChange: (() -> Void)?
    private var suppressChange = false

    private var profileID = 1
    private var storageKey: String {
        profileID == 1 ? "nuvio.library.v1" : "nuvio.library.v1.p\(profileID)"
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

    /// Saved items, newest first — the order the Library grid renders in.
    var sorted: [SavedLibraryItem] {
        items.values.sorted { $0.addedAt > $1.addedAt }
    }

    func contains(id: String, type: String) -> Bool {
        items["\(type)|\(id)"] != nil
    }

    func contains(_ meta: MetaItem) -> Bool { contains(id: meta.id, type: meta.type) }

    func toggle(_ meta: MetaItem) {
        if contains(meta) {
            remove(id: meta.id, type: meta.type)
        } else {
            add(SavedLibraryItem(meta: meta))
        }
    }

    func add(_ item: SavedLibraryItem) {
        items[item.key] = item
        save()
        if !suppressChange { onLocalChange?() }
    }

    func remove(id: String, type: String) {
        items.removeValue(forKey: "\(type)|\(id)")
        save()
        if !suppressChange { onLocalChange?() }
    }

    // MARK: - Sync bridge

    func allForSync() -> [SavedLibraryItem] { Array(items.values) }

    func mergeRemote(_ remote: [SavedLibraryItem]) {
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
              let decoded = try? JSONDecoder().decode([String: SavedLibraryItem].self, from: data) else { return }
        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
