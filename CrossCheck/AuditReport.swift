//
//  AuditReport.swift
//  CrossCheck
//

import Foundation

enum AuditReport {
    static func text(for audit: SafetyAudit) -> String {
        let score = SafetyAuditScorer.score(audit)
        var lines: [String] = [
            "CROSSCHECK OBSERVATION REPORT",
            ""
        ]

        if audit.isDemo {
            lines.append("FICTIONAL DEMONSTRATION (DEMO)")
            lines.append("This example is not a real incident or a verified crash record.")
            lines.append("")
        }

        lines.append("This is a preliminary, user-submitted observation for community discussion.")
        lines.append("It has not been submitted to any government agency.")
        lines.append("")
        lines.append("Location: \(audit.locationName)")
        lines.append(String(format: "Coordinates: %.5f, %.5f", audit.latitude, audit.longitude))
        lines.append("Observed: \(audit.observedAt.formatted(date: .long, time: .shortened))")
        lines.append("Severity: \(audit.severity.rawValue)")
        lines.append("")
        lines.append("Recorded concerns:")
        for concern in audit.concerns {
            lines.append("- \(concern.rawValue)")
        }

        let trimmedNotes = audit.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        lines.append("")
        if trimmedNotes.isEmpty {
            lines.append("Notes: none")
        } else {
            lines.append("Notes:")
            lines.append(trimmedNotes)
        }

        lines.append("")
        lines.append("Priority index: \(score.total) of \(score.maximum)")
        lines.append("How the index was calculated:")
        for item in score.contributions {
            lines.append("- \(item.label): +\(item.points)")
        }
        lines.append("")
        lines.append(score.disclaimer)
        lines.append("Observation count, selected severity, and this index are separate numbers.")

        return lines.joined(separator: "\n")
    }

    static func shareSubject(for audit: SafetyAudit) -> String {
        if audit.isDemo {
            return "DEMO: CrossCheck sample observation"
        }
        return "CrossCheck observation: \(audit.locationName)"
    }
}
