import Foundation

extension Notification.Name {
    static let appRouteReceived = Notification.Name("appRouteReceived")
}

/// Supported deep link routes.
/// URL scheme: `moneymanager://expense/<uuid>` and `moneymanager://group/<uuid>`
enum AppRoute: Hashable {
    case expense(UUID)
    case group(UUID)

    init?(url: URL) {
        guard url.scheme == "moneymanager" else { return nil }
        let host = url.host
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let idString = pathComponents.first, let id = UUID(uuidString: idString) else { return nil }

        switch host {
        case "expense": self = .expense(id)
        case "group":   self = .group(id)
        default:        return nil
        }
    }
}
