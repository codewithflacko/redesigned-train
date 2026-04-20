import Foundation
import SwiftUI

// MARK: - AppState
//
// Single source of truth for all shared data across portals.
// Any mutation here publishes to every view that holds this object,
// enabling real-time cross-role interactions:
//   • Parent marks child absent  → Driver sees ABSENT on that student
//   • Driver completes a stop    → Parent's stopsAway ticks down
//   • Driver status changes      → Parent's bus status badge updates
//   • Driver goes sick           → Dispatch sees the sick banner immediately

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    private init() {}

    @Published var drivers: [Driver] = Driver.sampleDrivers
    @Published var children: [Child] = Child.sampleChildren

    // -----------------------------------------------------------------------
    // Parent → Driver  |  Mark a child absent and mirror to their RouteStudent
    // -----------------------------------------------------------------------

    func setChildAbsent(_ childId: UUID, absent: Bool) {
        guard let ci = children.firstIndex(where: { $0.id == childId }) else { return }
        children[ci].isAbsentToday = absent

        // Match to RouteStudent by bus number + first name
        let busNumber  = children[ci].busTracking.busNumber
        let firstName  = children[ci].name.lowercased()

        for di in drivers.indices {
            guard drivers[di].busNumber == busNumber else { continue }
            for si in drivers[di].route.stops.indices {
                for sti in drivers[di].route.stops[si].students.indices {
                    let studentFirst = drivers[di].route.stops[si].students[sti].name
                        .components(separatedBy: " ").first?.lowercased() ?? ""
                    if studentFirst == firstName {
                        drivers[di].route.stops[si].students[sti].isAbsentToday = absent
                        // Notify the driver when a parent marks their student absent
                        if absent {
                            NotificationManager.shared.sendAbsenceAlert(
                                studentName: drivers[di].route.stops[si].students[sti].name,
                                busNumber:   busNumber,
                                stopName:    drivers[di].route.stops[si].name
                            )
                        }
                    }
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Driver → Parent  |  Stop completed — update bus position + stopsAway
    // -----------------------------------------------------------------------

    func driverCompletedStop(busNumber: String, newStopIndex: Int) {
        guard let di = drivers.firstIndex(where: { $0.busNumber == busNumber }) else { return }
        let driver = drivers[di]

        for ci in children.indices {
            guard children[ci].busTracking.busNumber == busNumber,
                  !children[ci].isAbsentToday else { continue }

            // Move bus pin to current stop coordinate
            if newStopIndex < driver.route.stops.count {
                children[ci].busTracking.busCoordinate =
                    driver.route.stops[newStopIndex].coordinate
            }

            // Decrement stopsAway
            let remaining = driver.route.stops.count - newStopIndex
            if remaining <= 0 {
                children[ci].busTracking.hasArrivedAtSchool = true
                children[ci].busTracking.status             = .arrivedAtSchool
                children[ci].busTracking.stopsAway          = nil
                // Notify parent their child has arrived
                NotificationManager.shared.sendArrivedAlert(
                    childName:  children[ci].name,
                    schoolName: children[ci].busTracking.schoolName,
                    childId:    children[ci].id
                )
            } else {
                let stopsAway = max(0, remaining - 1)
                children[ci].busTracking.stopsAway = stopsAway
                // Notify parent when bus is 2 or 1 stops away
                if stopsAway == 2 || stopsAway == 1 {
                    NotificationManager.shared.sendBusNearbyAlert(
                        childName:  children[ci].name,
                        stopsAway:  stopsAway,
                        busNumber:  busNumber,
                        childId:    children[ci].id
                    )
                }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Driver → Parent  |  Route status changed — update bus status badge
    // -----------------------------------------------------------------------

    func syncBusStatus(busNumber: String) {
        guard let di = drivers.firstIndex(where: { $0.busNumber == busNumber }) else { return }
        let driverStatus = drivers[di].route.status

        let newBusStatus: BusStatus
        switch driverStatus {
        case .inProgress:           newBusStatus = .onTime
        case .delayed(let reason):  newBusStatus = .delayed(reason: reason.rawValue)
        case .paused:               newBusStatus = .paused
        case .completed:            newBusStatus = .arrivedAtSchool
        case .notStarted:           newBusStatus = .onTime
        }

        for ci in children.indices {
            guard children[ci].busTracking.busNumber == busNumber else { continue }
            children[ci].busTracking.status = newBusStatus
        }
    }
}
