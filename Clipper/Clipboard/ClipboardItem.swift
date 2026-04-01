
import Foundation

/// A single entry in the clipboard history.
struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let content: String
    let date: Date
    var isPinned: Bool

    init(content: String, date: Date = .now, isPinned: Bool = false) {
        self.id = UUID()
        self.content = content
        self.date = date
        self.isPinned = isPinned
    }

    // MARK: - Derived helpers

    /// A short preview: first line, truncated to 120 chars.
    var preview: String {
        let first = content.components(separatedBy: .newlines).first ?? content
        return first.count > 120 ? String(first.prefix(120)) + "…" : first
    }

    /// Human-readable relative timestamp — "2m ago", "just now", etc.
    var relativeTime: String {
        let seconds = Int(-date.timeIntervalSinceNow)
        switch seconds {
        case ..<5:    return "just now"
        case ..<60:   return "\(seconds)s ago"
        case ..<3600: return "\(seconds / 60)m ago"
        case ..<86400: return "\(seconds / 3600)h ago"
        default:      return "\(seconds / 86400)d ago"
        }
    }
}
