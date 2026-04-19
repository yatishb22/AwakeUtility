import Foundation

protocol PowerMonitoring {
    var currentPowerSource: PowerSourceState { get async }
    var powerSourceUpdates: AsyncStream<PowerSourceState> { get }
}
