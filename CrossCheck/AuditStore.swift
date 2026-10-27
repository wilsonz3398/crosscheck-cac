//
//  AuditStore.swift
//  CrossCheck
//
//  Created by Wilson on 10/03/26.
//

import Foundation

@MainActor
final class AuditStore: ObservableObject {
    @Published private(set) var audits: [SafetyAudit] = []

    private let storageKey = "crosscheck.safetyAudits"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var hasDemoAudits: Bool {
        audits.contains(where: \.isDemo)
    }

    func audit(id: UUID) -> SafetyAudit? {
        audits.first { $0.id == id }
    }

    func save(_ audit: SafetyAudit) {
        if let index = audits.firstIndex(where: { $0.id == audit.id }) {
            audits[index] = audit
        } else {
            audits.insert(audit, at: 0)
        }
        persist()
    }

    func delete(_ audit: SafetyAudit) {
        audits.removeAll { $0.id == audit.id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        audits.remove(atOffsets: offsets)
        persist()
    }

    func removeDemoAudits() {
        audits.removeAll { $0.isDemo }
        persist()
    }

    func loadFictionalDemos() {
        let existingDemoIDs = Set(audits.filter(\.isDemo).map(\.id))
        let demos = Self.fictionalDemos.filter { !existingDemoIDs.contains($0.id) }
        audits.insert(contentsOf: demos, at: 0)
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else {
            audits = []
            return
        }

        do {
            audits = try JSONDecoder().decode([SafetyAudit].self, from: data)
        } catch {
            // Keep the app usable if stored data is missing or corrupted.
            audits = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(audits)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Avoid crashing if encoding fails; in-memory records remain for this session.
        }
    }

    /// Explicitly fictional demonstration records for walkthroughs and video.
    private static let fictionalDemos: [SafetyAudit] = [
        SafetyAudit(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-111111111111")!,
            locationName: "Market St & Van Ness Ave (DEMO)",
            latitude: 37.7752,
            longitude: -122.4193,
            observedAt: Date(timeIntervalSince1970: 1_720_000_000),
            concerns: [.blockedSightlines, .speedingConcerns],
            severity: .high,
            notes: "Fictional demonstration example. Not a real incident or verified crash record.",
            isDemo: true
        ),
        SafetyAudit(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-222222222222")!,
            locationName: "Mission St & 16th St (DEMO)",
            latitude: 37.7651,
            longitude: -122.4196,
            observedAt: Date(timeIntervalSince1970: 1_720_086_400),
            concerns: [.turningVehiclesNotYielding, .missingCrosswalkMarkings],
            severity: .medium,
            notes: "Fictional demonstration example for app walkthroughs only.",
            isDemo: true
        ),
        SafetyAudit(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-333333333333")!,
            locationName: "Geary Blvd & 19th Ave (DEMO)",
            latitude: 37.7805,
            longitude: -122.4780,
            observedAt: Date(timeIntervalSince1970: 1_720_172_800),
            concerns: [.longPedestrianCrossing, .poorNighttimeLighting],
            severity: .low,
            notes: "Fictional demonstration example. Do not treat as an actual safety incident.",
            isDemo: true
        )
    ]
}
