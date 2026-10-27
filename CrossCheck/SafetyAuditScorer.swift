//
//  SafetyAuditScorer.swift
//  CrossCheck
//
//  Observation-priority heuristic based only on selected concerns and severity.
//  This is not a crash probability, official rating, or validated engineering measure.
//

import Foundation

struct ScoreContribution: Identifiable, Equatable {
    let label: String
    let points: Int

    var id: String { label }
}

struct ObservationPriorityScore: Equatable {
    /// Sum of concern weights plus the severity adjustment.
    let total: Int
    /// Highest index possible if every concern is selected and severity is High.
    let maximum: Int
    let contributions: [ScoreContribution]
    let disclaimer: String
}

enum SafetyAuditScorer {
    /// Higher values mean the concern is treated as more urgent to discuss:
    /// - Turning / speeding: 5 — describe direct vehicle-conflict observations.
    /// - Blocked sightlines: 4 — describe reduced ability to see other road users.
    /// - Crossing length, faded markings, lighting: 3 — describe crossing conditions.
    /// - Other concern: 2 — catch-all with no extra assumed risk.
    static let concernWeights: [SafetyConcern: Int] = [
        .blockedSightlines: 4,
        .turningVehiclesNotYielding: 5,
        .speedingConcerns: 5,
        .longPedestrianCrossing: 3,
        .missingCrosswalkMarkings: 3,
        .poorNighttimeLighting: 3,
        .other: 2
    ]

    /// Extra points from the observer's selected severity; kept separate from concern weights so a High rating does not hide.
    static let severityPoints: [AuditSeverity: Int] = [
        .low: 2,
        .medium: 6,
        .high: 10
    ]

    static let disclaimer = "Unvalidated observation-priority heuristic. It does not predict crashes and is not an official engineering or government safety rating."

    static var maximumIndex: Int {
        concernWeights.values.reduce(0, +) + (severityPoints[.high] ?? 0)
    }

    static func score(_ audit: SafetyAudit) -> ObservationPriorityScore {
        score(concerns: audit.concerns, severity: audit.severity)
    }

    /// Deterministic: same concerns and severity always produce the same index.
    static func score(
        concerns: [SafetyConcern],
        severity: AuditSeverity
    ) -> ObservationPriorityScore {
        let uniqueConcerns = SafetyConcern.allCases.filter { concerns.contains($0) }

        var contributions: [ScoreContribution] = uniqueConcerns.map { concern in
            ScoreContribution(
                label: concern.rawValue,
                points: concernWeights[concern] ?? 0
            )
        }

        let severityValue = severityPoints[severity] ?? 0
        contributions.append(
            ScoreContribution(
                label: "Selected severity: \(severity.rawValue)",
                points: severityValue
            )
        )

        let total = contributions.reduce(0) { $0 + $1.points }
        return ObservationPriorityScore(
            total: total,
            maximum: maximumIndex,
            contributions: contributions,
            disclaimer: disclaimer
        )
    }
}
