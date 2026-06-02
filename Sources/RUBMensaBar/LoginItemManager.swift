import Foundation
import ServiceManagement

enum LoginItemManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var canModify: Bool {
        SMAppService.mainApp.status != .notFound
    }

    static var statusText: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Aktiv"
        case .notRegistered:
            return "Nicht aktiv"
        case .requiresApproval:
            return "Freigabe in den macOS-Anmeldeobjekten erforderlich"
        case .notFound:
            return "Nicht verfügbar in diesem Entwicklungs-Bundle"
        @unknown default:
            return "Unbekannter Status"
        }
    }

    static func setEnabled(_ isEnabled: Bool) throws {
        if isEnabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval else { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
