import Foundation
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @Published var defaultLeadMinutes: Int = 15
    @Published var defaultHoldMinutes: Int = 15
    @Published var defaultRequiresAC: Bool = true
    @Published var launchAtLogin: Bool = false

    private let defaults = UserDefaults.standard
    private let defaultLeadKey = "settings.defaultLeadMinutes"
    private let defaultHoldKey = "settings.defaultHoldMinutes"
    private let defaultRequiresACKey = "settings.defaultRequiresAC"
    private let launchAtLoginKey = "settings.launchAtLogin"

    init() {
        defaultLeadMinutes = defaults.object(forKey: defaultLeadKey) as? Int ?? 15
        defaultHoldMinutes = defaults.object(forKey: defaultHoldKey) as? Int ?? 15
        defaultRequiresAC = defaults.object(forKey: defaultRequiresACKey) as? Bool ?? true
        launchAtLogin = defaults.object(forKey: launchAtLoginKey) as? Bool ?? false
    }

    func save() {
        defaults.set(defaultLeadMinutes, forKey: defaultLeadKey)
        defaults.set(defaultHoldMinutes, forKey: defaultHoldKey)
        defaults.set(defaultRequiresAC, forKey: defaultRequiresACKey)
        defaults.set(launchAtLogin, forKey: launchAtLoginKey)
    }
}
