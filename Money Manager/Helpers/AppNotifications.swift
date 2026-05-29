import Foundation

extension Notification.Name {
    static let appRouteReceived = Notification.Name("appRouteReceived")
    static let authSessionExpired = Notification.Name("authSessionExpired")
    static let authStateDidChange = Notification.Name("authStateDidChange")
    static let syncSessionOrphaned = Notification.Name("syncSessionOrphaned")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidSwitchAccount = Notification.Name("userDidSwitchAccount")
}
