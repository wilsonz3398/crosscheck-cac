//
//  SafetyAudit.swift
//  CrossCheck
//

import CoreLocation
import Foundation

enum SafetyConcern: String, Codable, CaseIterable, Identifiable, Hashable {
    case blockedSightlines = "Blocked sightlines"
    case turningVehiclesNotYielding = "Turning vehicles not yielding"
    case speedingConcerns = "Speeding concerns"
    case longPedestrianCrossing = "Long pedestrian crossing"
    case missingCrosswalkMarkings = "Missing or faded crosswalk markings"
    case poorNighttimeLighting = "Poor nighttime lighting"
    case other = "Other concern"

    var id: String { rawValue }
}

enum AuditSeverity: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

struct SafetyAudit: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var locationName: String
    var latitude: Double
    var longitude: Double
    var observedAt: Date
    var concerns: [SafetyConcern]
    var severity: AuditSeverity
    var notes: String
    var isDemo: Bool

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MapDefaults {
    static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
}
