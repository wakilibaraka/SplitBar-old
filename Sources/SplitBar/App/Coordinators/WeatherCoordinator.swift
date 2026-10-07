import Foundation

/// The refresh surface the coordinator needs from the weather service.
@MainActor
protocol WeatherRefreshing: AnyObject {
    var currentState: WeatherState { get }
    var onUpdate: ((WeatherState) -> Void)? { get set }
    func refresh() async
}

@MainActor
protocol WeatherCoordinating: AnyObject {
    var currentState: WeatherState { get }
    var stateDidChange: ((WeatherState) -> Void)? { get set }
    func start()
    func refresh()
}

/// Owns the weather refresh and decides what the widget shows for a given reading.
///
/// Extracted from `AppRuntimeController`, which forwarded the service's updates
/// straight into the taskbar state object. The service keeps its cache and its
/// periodic timer; this type owns when updates start and how a reading is
/// presented.
@MainActor
final class WeatherCoordinator: WeatherCoordinating {
    private let service: any WeatherRefreshing
    private(set) var currentState: WeatherState
    var stateDidChange: ((WeatherState) -> Void)?

    init(service: any WeatherRefreshing) {
        self.service = service
        self.currentState = service.currentState
    }

    /// Seeds the current reading and subscribes to later ones.
    ///
    /// The widget starts in `.loading` rather than showing the cached reading as
    /// final, so a stale cache is never mistaken for live weather.
    func start() {
        stateDidChange?(currentState)
        service.onUpdate = { [weak self] state in
            guard let self else { return }
            self.currentState = state
            self.stateDidChange?(state)
        }
    }

    func refresh() {
        Task { [weak self] in
            await self?.service.refresh()
        }
    }

    /// The widget state for a reading.
    ///
    /// A sample reading is not an error state to retry: the service already
    /// decided it has no live data, so the widget says so in words rather than
    /// spinning or showing an empty card.
    static func widgetState(for state: WeatherState) -> WidgetState {
        state.isLive ? .loaded : .error("Weather unavailable — showing sample")
    }
}

extension WeatherService: WeatherRefreshing {}
