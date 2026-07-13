import Foundation

/// Top-level quality split: the resolution the stream advertises. This is the
/// primary grouping — every addon block is divided into these first, then each
/// resolution is sub-divided by file size.
enum ResolutionTier: Int, CaseIterable {
    case uhd2160 = 0
    case fhd1080
    case hd720
    case sd480
    case other

    var title: String {
        switch self {
        case .uhd2160: return "2160p"
        case .fhd1080: return "1080p"
        case .hd720:   return "720p"
        case .sd480:   return "480p"
        case .other:   return "Other"
        }
    }

    static func from(resolutionLabel: String?) -> ResolutionTier {
        switch resolutionLabel {
        case "2160p": return .uhd2160
        case "1080p": return .fhd1080
        case "720p":  return .hd720
        case "480p":  return .sd480
        default:      return .other
        }
    }
}

/// Second-level split: the file-size band, nested under a resolution. A KNOWN
/// size under 250 MB is confirmed junk (the 0/14 MB decoy "movies" some addons
/// return) and dropped; an unknown size sorts into its own band last.
enum SizeBucket: Int, CaseIterable {
    case mb250to4GB = 0
    case gb4to10
    case gb10to20
    case gb20to30
    case gb30plus
    case unknown

    var title: String {
        switch self {
        case .mb250to4GB: return "250 MB – 4 GB"
        case .gb4to10:    return "4 – 10 GB"
        case .gb10to20:   return "10 – 20 GB"
        case .gb20to30:   return "20 – 30 GB"
        case .gb30plus:   return "30 GB+"
        case .unknown:    return "Size Unknown"
        }
    }

    private static let mb: Int64 = 1_048_576
    private static let gb: Int64 = 1_073_741_824

    /// nil = confirmed junk (a KNOWN size below 250 MB).
    static func from(bytes: Int64?) -> SizeBucket? {
        guard let bytes, bytes > 0 else { return .unknown }
        switch bytes {
        case ..<(250 * mb): return nil
        case ..<(4 * gb):   return .mb250to4GB
        case ..<(10 * gb):  return .gb4to10
        case ..<(20 * gb):  return .gb10to20
        case ..<(30 * gb):  return .gb20to30
        default:            return .gb30plus
        }
    }
}

/// The renderable tree for one addon: resolution sections, each holding size
/// subsections. Generic enough to also carry the flat "filters off" list (one
/// untitled section + subsection). The Sources page renders it as
/// addon header → resolution header → size sub-header → rows; the flat
/// `entries` view is used by the in-player panel and failover.
struct AddonSourceGroup: Identifiable {
    var id: String { addonName }
    let addonName: String
    let sections: [SourceSection]

    var entries: [StreamEntry] { sections.flatMap { $0.entries } }
}

struct SourceSection: Identifiable {
    let id: String
    /// Resolution header ("2160p" …). Empty when the list isn't tiered.
    let title: String
    let subsections: [SourceSubsection]

    var entries: [StreamEntry] { subsections.flatMap(\.entries) }
}

struct SourceSubsection: Identifiable {
    let id: String
    /// Size-band sub-header ("10 – 20 GB" …). Empty when not sub-tiered.
    let title: String
    let entries: [StreamEntry]
}

enum SourceSelection {
    /// First-seen order of the addons that returned links.
    private static func addonOrder(_ entries: [StreamEntry]) -> [String] {
        var order: [String] = []
        var seen = Set<String>()
        for entry in entries where seen.insert(entry.addonName).inserted {
            order.append(entry.addonName)
        }
        return order
    }

    /// Debrid-cached / direct links first, then the rest — stable, so the
    /// addon's own ordering survives within each half. Cached links play
    /// instantly; an uncached torrent must be downloaded by the debrid service
    /// first, so those only fill in after the cached ones.
    static func cachedFirst(_ entries: [StreamEntry]) -> [StreamEntry] {
        entries.filter(\.isInstant) + entries.filter { !$0.isInstant }
    }

    /// Filters ON: per addon → resolution sections (2160→1080→720→480→other)
    /// → size subsections (250 MB–4 GB … 30 GB+, unknown last) → cached-first,
    /// capped at `perBucket` links per resolution×size cell. Junk (< 250 MB) is
    /// dropped; empty resolutions/buckets are omitted.
    static func byAddon(_ entries: [StreamEntry], perBucket: Int) -> [AddonSourceGroup] {
        let cap = max(perBucket, 1)
        return addonOrder(entries).compactMap { name in
            let own = entries.filter { $0.addonName == name }
            let sections: [SourceSection] = ResolutionTier.allCases.compactMap { res in
                let inRes = own.filter { ResolutionTier.from(resolutionLabel: $0.resolutionLabel) == res }
                guard !inRes.isEmpty else { return nil }
                var byBucket: [SizeBucket: [StreamEntry]] = [:]
                for entry in inRes {
                    guard let bucket = SizeBucket.from(bytes: entry.sizeBytes) else { continue }
                    byBucket[bucket, default: []].append(entry)
                }
                let subs: [SourceSubsection] = SizeBucket.allCases.compactMap { bucket in
                    guard let tierEntries = byBucket[bucket] else { return nil }
                    let picked = Array(cachedFirst(tierEntries).prefix(cap))
                    guard !picked.isEmpty else { return nil }
                    return SourceSubsection(id: "\(name).\(res.rawValue).\(bucket.rawValue)",
                                            title: bucket.title, entries: picked)
                }
                guard !subs.isEmpty else { return nil }
                return SourceSection(id: "\(name).\(res.rawValue)", title: res.title, subsections: subs)
            }
            return sections.isEmpty ? nil : AddonSourceGroup(addonName: name, sections: sections)
        }
    }

    /// Filters OFF: each addon's links as returned (debrid-cached floated to
    /// the top), capped per addon, no tiers — one untitled section.
    static func byAddonUnfiltered(_ entries: [StreamEntry], cap: Int) -> [AddonSourceGroup] {
        addonOrder(entries).compactMap { name in
            let own = entries.filter { $0.addonName == name }
            let capped = Array(cachedFirst(own).prefix(max(cap, 1)))
            guard !capped.isEmpty else { return nil }
            return AddonSourceGroup(
                addonName: name,
                sections: [SourceSection(id: "\(name).all", title: "",
                    subsections: [SourceSubsection(id: "\(name).all.0", title: "", entries: capped)])]
            )
        }
    }

    /// Flat, tier-ordered list (in-player Sources panel + failover ordering).
    static func select(_ entries: [StreamEntry], perBucket: Int) -> [StreamEntry] {
        byAddon(entries, perBucket: perBucket).flatMap(\.entries)
    }

    static func selectUnfiltered(_ entries: [StreamEntry], cap: Int) -> [StreamEntry] {
        byAddonUnfiltered(entries, cap: cap).flatMap(\.entries)
    }
}
