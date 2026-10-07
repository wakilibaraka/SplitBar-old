import Foundation
import Testing

@testable import SplitBar

private final class SpyWeatherService: WeatherRefreshing {
    private(set) var refreshCount = 0
    var onUpdate: ((WeatherState) -> Void)?
    var currentState: WeatherState

    init(currentState: WeatherState) {
        self.currentState = currentState
    }

    func refresh() async {
        refreshCount += 1
    }

    /// Simulates the service pushing a new reading.
    func push(_ state: WeatherState) {
        currentState = state
        onUpdate?(state)
    }
}

private func reading(live: Bool, temperature: Double = 12) -> WeatherState {
    WeatherState(
        cityName: "Izmir",
        temperatureCelsius: temperature,
        conditionText: live ? "Clear" : "Sample",
        symbolName: "sun.max",
        highCelsius: 18,
        lowCelsius: 7,
        hourly: [],
        daily: [],
        isLive: live,
        lastUpdated: Date(timeIntervalSinceNow: -60)
    )
}

@Suite("Weather coordinator")
@MainActor
struct WeatherCoordinatorTests {
    @Test("starting publishes the cached reading straight away") func startPublishesCache() {
        let service = SpyWeatherService(currentState: reading(live: false))
        let coordinator = WeatherCoordinator(service: service)
        var published: [WeatherState] = []
        coordinator.stateDidChange = { published.append($0) }

        coordinator.start()

        #expect(published.count == 1)
        #expect(published.first?.cityName == "Izmir")
    }

    @Test("later readings are forwarded and become the current state") func forwardsUpdates() {
        let service = SpyWeatherService(currentState: reading(live: false))
        let coordinator = WeatherCoordinator(service: service)
        var published: [WeatherState] = []
        coordinator.stateDidChange = { published.append($0) }
        coordinator.start()

        service.push(reading(live: true, temperature: 21))

        #expect(published.count == 2)
        #expect(coordinator.currentState.isLive)
        #expect(coordinator.currentState.formattedTemperature == "21°")
    }

    @Test("refresh asks the service for a new reading") func refreshDelegates() async throws {
        let service = SpyWeatherService(currentState: reading(live: true))
        let coordinator = WeatherCoordinator(service: service)

        coordinator.refresh()

        // refresh() hops to a task, so give it a moment to run.
        for _ in 0..<100 where service.refreshCount == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.refreshCount == 1)
    }

    @Test("a live reading loads and a sample one explains itself") func widgetStateMapping() {
        if case .loaded = WeatherCoordinator.widgetState(for: reading(live: true)) {
            // expected
        } else {
            Issue.record("a live reading must load the widget")
        }

        guard case .error(let message) = WeatherCoordinator.widgetState(for: reading(live: false)) else {
            Issue.record("a sample reading must not claim to be loaded")
            return
        }
        #expect(message == "Weather unavailable — showing sample")
    }
}
