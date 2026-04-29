import Foundation

extension Notification.Name {
    static let appRouteReceived = Notification.Name("appRouteReceived")
    static let authSessionExpired = Notification.Name("authSessionExpired")
    static let authStateDidChange = Notification.Name("authStateDidChange")
    static let syncSessionOrphaned = Notification.Name("syncSessionOrphaned")
    static let userDidLogout = Notification.Name("userDidLogout")
}

/// Supported deep link routes.
/// URL scheme: `moneymanager://transaction/<uuid>` and `moneymanager://group/<uuid>`
enum AppRoute: Hashable {
    case transaction(UUID)
    case group(UUID)

    init?(url: URL) {
        guard url.scheme == "moneymanager" else { return nil }
        let host = url.host
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let idString = pathComponents.first, let id = UUID(uuidString: idString) else { return nil }

        switch host {
        case "transaction": self = .transaction(id)
        case "group":   self = .group(id)
        default:        return nil
        }
    }
}
