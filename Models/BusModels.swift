import Foundation
import SwiftUI
import CoreLocation

// MARK: - Bus Status
enum BusStatus: Equatable {
    case onTime
    case paused
    case delayed(reason: String)
    case arrivedAtSchool

    var color: Color {
        switch self {
        case .onTime:          return Color(hex: "2ECC71")
        case .paused:          return Color(hex: "F5A623")
        case .delayed:         return Color(hex: "E74C3C")
        case .arrivedAtSchool: return Color(hex: "2ECC71")
        }
    }

    var label: String {
        switch self {
        case .onTime:                  return "On Time"
        case .paused:                  return "Paused"
        case .delayed(let reason):     return "Delayed — \(reason)"
        case .arrivedAtSchool:         return "Arrived at School"
        }
    }

    var icon: String {
        switch self {
        case .onTime:          return "checkmark.circle.fill"
        case .paused:          return "pause.circle.fill"
        case .delayed:         return "exclamationmark.triangle.fill"
        case .arrivedAtSchool: return "building.columns.fill"
        }
    }

    static func == (lhs: BusStatus, rhs: BusStatus) -> Bool {
        switch (lhs, rhs) {
        case (.onTime, .onTime), (.paused, .paused), (.arrivedAtSchool, .arrivedAtSchool): return true
        case (.delayed(let a), .delayed(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Bus Tracking
struct BusTracking {
    let busNumber: String
    let driverName: String
    var status: BusStatus
    var stopsAway: Int?             // nil when arrived or not yet en route
    var hasArrivedAtSchool: Bool
    var busCoordinate: CLLocationCoordinate2D
    var stopCoordinate: CLLocationCoordinate2D
    var schoolCoordinate: CLLocationCoordinate2D
    var estimatedArrival: String?   // e.g. "7:42 AM"
    var stopName: String
    var schoolName: String
}

// MARK: - Child
struct Child: Identifiable {
    let id: UUID
    let name: String
    let grade: String
    let avatarColor: Color
    var isAbsentToday: Bool
    var busTracking: BusTracking
    var photoData: Data?            // nil = show colored initial fallback

    init(name: String, grade: String, avatarColor: Color,
         isAbsentToday: Bool = false, photoData: Data? = nil, busTracking: BusTracking) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.avatarColor = avatarColor
        self.isAbsentToday = isAbsentToday
        self.photoData = photoData
        self.busTracking = busTracking
    }
}

// MARK: - Route Student
struct RouteStudent: Identifiable {
    let id: UUID
    let name: String
    let grade: String
    var isPickedUp: Bool
    var isAbsentToday: Bool

    init(name: String, grade: String, isPickedUp: Bool = false, isAbsentToday: Bool = false) {
        self.id = UUID()
        self.name = name
        self.grade = grade
        self.isPickedUp = isPickedUp
        self.isAbsentToday = isAbsentToday
    }
}

// MARK: - Route Stop
struct RouteStop: Identifiable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    var students: [RouteStudent]
    var isCompleted: Bool
    var estimatedArrival: String

    init(name: String, coordinate: CLLocationCoordinate2D,
         students: [RouteStudent], isCompleted: Bool = false, estimatedArrival: String) {
        self.id = UUID()
        self.name = name
        self.coordinate = coordinate
        self.students = students
        self.isCompleted = isCompleted
        self.estimatedArrival = estimatedArrival
    }

    var boardingCount: Int { students.filter { !$0.isAbsentToday }.count }
    var pickedUpCount: Int { students.filter { $0.isPickedUp }.count }
}

// MARK: - Route Status
enum RouteStatus: Equatable {
    case notStarted
    case inProgress
    case paused(reason: PauseReason)
    case delayed(reason: DelayReason)
    case completed

    enum PauseReason: String, CaseIterable {
        case childBoarding  = "Child Boarding Issue"
        case waitingChild   = "Waiting on Child"
        case trafficLight   = "Traffic Signal"
        case other          = "Other"
    }

    enum DelayReason: String, CaseIterable {
        case heavyTraffic   = "Heavy Traffic"
        case accident       = "Road Accident"
        case roadClosure    = "Road Closure"
        case busMaintenance = "Bus Maintenance"
        case medicalEmergency = "Medical Emergency"
        case studentIncident  = "Student Incident"
        case weatherConditions = "Weather Conditions"
        case other          = "Other"
    }

    var label: String {
        switch self {
        case .notStarted:               return "Not Started"
        case .inProgress:               return "In Progress"
        case .paused(let r):            return "Paused — \(r.rawValue)"
        case .delayed(let r):           return "Delayed — \(r.rawValue)"
        case .completed:                return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .notStarted:   return .secondary
        case .inProgress:   return Color(hex: "2ECC71")
        case .paused:       return Color(hex: "F5A623")
        case .delayed:      return Color(hex: "E74C3C")
        case .completed:    return Color(hex: "2F80ED")
        }
    }

    var icon: String {
        switch self {
        case .notStarted:   return "clock"
        case .inProgress:   return "bus.fill"
        case .paused:       return "pause.circle.fill"
        case .delayed:      return "exclamationmark.triangle.fill"
        case .completed:    return "checkmark.seal.fill"
        }
    }

    static func == (lhs: RouteStatus, rhs: RouteStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notStarted, .notStarted), (.inProgress, .inProgress), (.completed, .completed): return true
        case (.paused(let a), .paused(let b)):   return a == b
        case (.delayed(let a), .delayed(let b)): return a == b
        default: return false
        }
    }
}

// MARK: - Driver Route
struct DriverRoute {
    var stops: [RouteStop]
    var currentStopIndex: Int
    var status: RouteStatus
    var startedAt: Date?

    var completedStops: Int    { stops.filter { $0.isCompleted }.count }
    var totalStops: Int        { stops.count }
    var allStudents: [RouteStudent] { stops.flatMap { $0.students } }
    var totalStudents: Int     { allStudents.filter { !$0.isAbsentToday }.count }
    var pickedUpStudents: Int  { allStudents.filter { $0.isPickedUp }.count }
    var remainingStops: Int    { totalStops - completedStops }

    var currentStop: RouteStop? {
        guard currentStopIndex < stops.count else { return nil }
        return stops[currentStopIndex]
    }
    var nextStop: RouteStop? {
        let next = currentStopIndex + 1
        guard next < stops.count else { return nil }
        return stops[next]
    }
}

// MARK: - Driver
struct Driver: Identifiable {
    let id: UUID
    let name: String
    let busNumber: String
    let routeName: String
    let avatarColor: Color
    var isSick: Bool
    var route: DriverRoute

    init(name: String, busNumber: String, routeName: String,
         avatarColor: Color, isSick: Bool = false, route: DriverRoute) {
        self.id = UUID()
        self.name = name
        self.busNumber = busNumber
        self.routeName = routeName
        self.avatarColor = avatarColor
        self.isSick = isSick
        self.route = route
    }
}

// MARK: - Driver Sample Data
extension Driver {
    static var sampleDrivers: [Driver] = [
        Driver(
            name: "Mr. Mark", busNumber: "42", routeName: "Route 7A",
            avatarColor: Color(hex: "2F80ED"),
            route: DriverRoute(
                stops: [
                    RouteStop(name: "Oak St & Main Ave",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7490, longitude: -84.3900),
                              students: [
                                RouteStudent(name: "Emma Johnson", grade: "5th"),
                                RouteStudent(name: "Liam Johnson", grade: "3rd")
                              ], isCompleted: true, estimatedArrival: "7:15 AM"),
                    RouteStop(name: "Elm Dr & 5th St",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7510, longitude: -84.3880),
                              students: [
                                RouteStudent(name: "Marcus Thomas", grade: "4th", isPickedUp: true),
                                RouteStudent(name: "Sofia Rivera", grade: "2nd", isPickedUp: true)
                              ], isCompleted: true, estimatedArrival: "7:22 AM"),
                    RouteStop(name: "Pine Ave & Oak Blvd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7525, longitude: -84.3858),
                              students: [
                                RouteStudent(name: "Tyler Brooks", grade: "5th"),
                                RouteStudent(name: "Ava Mitchell", grade: "3rd"),
                                RouteStudent(name: "Noah Chen", grade: "1st", isAbsentToday: true)
                              ], isCompleted: false, estimatedArrival: "7:30 AM"),
                    RouteStop(name: "Cedar Ln & 3rd Ave",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7540, longitude: -84.3840),
                              students: [
                                RouteStudent(name: "Isabella Park", grade: "4th"),
                                RouteStudent(name: "Ethan Walker", grade: "2nd")
                              ], isCompleted: false, estimatedArrival: "7:38 AM"),
                    RouteStop(name: "Maple St & Park Rd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7555, longitude: -84.3822),
                              students: [
                                RouteStudent(name: "Olivia Scott", grade: "5th"),
                                RouteStudent(name: "Lucas Davis", grade: "3rd"),
                                RouteStudent(name: "Charlotte Flynn", grade: "2nd")
                              ], isCompleted: false, estimatedArrival: "7:45 AM"),
                    RouteStop(name: "Birch Ct & 1st Ave",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                              students: [
                                RouteStudent(name: "James King", grade: "4th"),
                                RouteStudent(name: "Amelia Ross", grade: "1st")
                              ], isCompleted: false, estimatedArrival: "7:52 AM")
                ],
                currentStopIndex: 2,
                status: .inProgress,
                startedAt: Calendar.current.date(byAdding: .minute, value: -18, to: Date())
            )
        ),
        Driver(
            name: "Mrs. White", busNumber: "17", routeName: "Route 3B",
            avatarColor: Color(hex: "9B59B6"),
            route: DriverRoute(
                stops: [
                    RouteStop(name: "Sunrise Blvd & 2nd St",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7480, longitude: -84.3920),
                              students: [
                                RouteStudent(name: "Mia Turner", grade: "1st", isPickedUp: true),
                                RouteStudent(name: "Carlos Reyes", grade: "3rd", isPickedUp: true)
                              ], isCompleted: true, estimatedArrival: "7:10 AM"),
                    RouteStop(name: "Willow Ave & Church Rd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7495, longitude: -84.3905),
                              students: [
                                RouteStudent(name: "Grace Lee", grade: "4th", isPickedUp: true),
                                RouteStudent(name: "Henry Moore", grade: "2nd", isPickedUp: true),
                                RouteStudent(name: "Lily Zhang", grade: "5th", isPickedUp: true)
                              ], isCompleted: true, estimatedArrival: "7:18 AM"),
                    RouteStop(name: "Poplar Dr & 7th Ave",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7515, longitude: -84.3888),
                              students: [
                                RouteStudent(name: "Oscar Brown", grade: "3rd"),
                                RouteStudent(name: "Zoe Harris", grade: "1st", isAbsentToday: true)
                              ], isCompleted: false, estimatedArrival: "7:26 AM"),
                    RouteStop(name: "Chestnut St & 10th Blvd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7530, longitude: -84.3870),
                              students: [
                                RouteStudent(name: "Ella Wilson", grade: "4th"),
                                RouteStudent(name: "Jackson Adams", grade: "5th")
                              ], isCompleted: false, estimatedArrival: "7:34 AM"),
                    RouteStop(name: "Dogwood Ln & School Rd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                              students: [
                                RouteStudent(name: "Sophia Carter", grade: "2nd"),
                                RouteStudent(name: "Benjamin Hall", grade: "3rd")
                              ], isCompleted: false, estimatedArrival: "7:42 AM")
                ],
                currentStopIndex: 2,
                status: .inProgress,
                startedAt: Calendar.current.date(byAdding: .minute, value: -22, to: Date())
            )
        ),
        Driver(
            name: "Mr. Alex", busNumber: "28", routeName: "Route 5C",
            avatarColor: Color(hex: "E67E22"),
            route: DriverRoute(
                stops: [
                    RouteStop(name: "Valley Rd & Grove St",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7460, longitude: -84.3940),
                              students: [
                                RouteStudent(name: "Aiden Murphy", grade: "5th"),
                                RouteStudent(name: "Chloe Nelson", grade: "4th")
                              ], isCompleted: false, estimatedArrival: "7:20 AM"),
                    RouteStop(name: "Hickory Ave & Lake Dr",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7475, longitude: -84.3925),
                              students: [
                                RouteStudent(name: "Ryan Cooper", grade: "2nd"),
                                RouteStudent(name: "Nora Evans", grade: "3rd"),
                                RouteStudent(name: "Dylan Foster", grade: "1st")
                              ], isCompleted: false, estimatedArrival: "7:28 AM"),
                    RouteStop(name: "Magnolia St & Bridge Rd",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7492, longitude: -84.3908),
                              students: [
                                RouteStudent(name: "Penelope Gray", grade: "4th"),
                                RouteStudent(name: "Logan Reed", grade: "5th")
                              ], isCompleted: false, estimatedArrival: "7:36 AM")
                ],
                currentStopIndex: 0,
                status: .notStarted
            )
        ),
        Driver(
            name: "Ms. Erica", busNumber: "33", routeName: "Route 2D",
            avatarColor: Color(hex: "E74C3C"),
            route: DriverRoute(
                stops: [
                    RouteStop(name: "Rosewood Ave & 4th St",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7470, longitude: -84.3932),
                              students: [
                                RouteStudent(name: "Scarlett Green", grade: "3rd", isPickedUp: true),
                                RouteStudent(name: "Miles Bennett", grade: "2nd", isPickedUp: true)
                              ], isCompleted: true, estimatedArrival: "7:05 AM"),
                    RouteStop(name: "Lakeview Dr & 8th Ave",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7488, longitude: -84.3912),
                              students: [
                                RouteStudent(name: "Aurora Lewis", grade: "5th", isPickedUp: true),
                                RouteStudent(name: "Finn Clark", grade: "4th", isPickedUp: true),
                                RouteStudent(name: "Hazel Young", grade: "1st", isPickedUp: true)
                              ], isCompleted: true, estimatedArrival: "7:13 AM"),
                    RouteStop(name: "Riverside School Drop-off",
                              coordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                              students: [],
                              isCompleted: true, estimatedArrival: "7:28 AM")
                ],
                currentStopIndex: 2,
                status: .completed,
                startedAt: Calendar.current.date(byAdding: .minute, value: -45, to: Date())
            )
        )
    ]
}

extension Child {
    static var sampleChildren: [Child] = [
        Child(
            name: "Emma",
            grade: "5th Grade",
            avatarColor: Color(hex: "FF6B9D"),
            busTracking: BusTracking(
                busNumber: "42",
                driverName: "Mr. Davis",
                status: .onTime,
                stopsAway: 3,
                hasArrivedAtSchool: false,
                busCoordinate: CLLocationCoordinate2D(latitude: 33.7185, longitude: -84.4320),
                stopCoordinate: CLLocationCoordinate2D(latitude: 33.7375, longitude: -84.4065),
                schoolCoordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                estimatedArrival: "7:42 AM",
                stopName: "Oak St & Main Ave",
                schoolName: "Riverside Elementary"
            )
        ),
        Child(
            name: "Liam",
            grade: "3rd Grade",
            avatarColor: Color(hex: "4A90D9"),
            busTracking: BusTracking(
                busNumber: "42",
                driverName: "Mr. Davis",
                status: .delayed(reason: "Traffic"),
                stopsAway: 7,
                hasArrivedAtSchool: false,
                busCoordinate: CLLocationCoordinate2D(latitude: 33.7140, longitude: -84.4280),
                stopCoordinate: CLLocationCoordinate2D(latitude: 33.7350, longitude: -84.4048),
                schoolCoordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                estimatedArrival: "8:05 AM",
                stopName: "Oak St & Main Ave",
                schoolName: "Riverside Elementary"
            )
        ),
        Child(
            name: "Mia",
            grade: "1st Grade",
            avatarColor: Color(hex: "9B59B6"),
            busTracking: BusTracking(
                busNumber: "17",
                driverName: "Ms. Carter",
                status: .arrivedAtSchool,
                stopsAway: nil,
                hasArrivedAtSchool: true,
                busCoordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                stopCoordinate: CLLocationCoordinate2D(latitude: 33.7498, longitude: -84.3875),
                schoolCoordinate: CLLocationCoordinate2D(latitude: 33.7565, longitude: -84.3815),
                estimatedArrival: nil,
                stopName: "Elm Dr & 5th St",
                schoolName: "Riverside Elementary"
            )
        )
    ]
}

