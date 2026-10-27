//
//  ObservationSummary.swift
//  CrossCheck
//

import Foundation
import SwiftUI

struct ObservationSummary: Equatable {
    let includedCount: Int
    let userCount: Int
    let demoCount: Int
    let countsByConcern: [SafetyConcern: Int]
    let countsBySeverity: [AuditSeverity: Int]
    let mostFrequentConcerns: [ConcernFrequency]
}

struct ConcernFrequency: Identifiable, Equatable {
    let concern: SafetyConcern
    let count: Int

    var id: String { concern.rawValue }
}

enum ObservationSummaryBuilder {
    /// Counts are derived only from the audits passed in, after the demo filter.
    static func make(from audits: [SafetyAudit], includeDemos: Bool) -> ObservationSummary {
        let userCount = audits.filter { !$0.isDemo }.count
        let demoCount = audits.filter(\.isDemo).count
        let included = includeDemos ? audits : audits.filter { !$0.isDemo }

        var concernCounts: [SafetyConcern: Int] = [:]
        for concern in SafetyConcern.allCases {
            concernCounts[concern] = 0
        }
        for audit in included {
            let unique = Set(audit.concerns)
            for concern in unique {
                concernCounts[concern, default: 0] += 1
            }
        }

        var severityCounts: [AuditSeverity: Int] = [:]
        for severity in AuditSeverity.allCases {
            severityCounts[severity] = 0
        }
        for audit in included {
            severityCounts[audit.severity, default: 0] += 1
        }

        let ranked = SafetyConcern.allCases
            .map { ConcernFrequency(concern: $0, count: concernCounts[$0] ?? 0) }
            .filter { $0.count > 0 }
            .sorted { lhs, rhs in
                if lhs.count == rhs.count {
                    return lhs.concern.rawValue < rhs.concern.rawValue
                }
                return lhs.count > rhs.count
            }

        return ObservationSummary(
            includedCount: included.count,
            userCount: userCount,
            demoCount: demoCount,
            countsByConcern: concernCounts,
            countsBySeverity: severityCounts,
            mostFrequentConcerns: ranked
        )
    }
}

struct ObservationSummaryCard: View {
    let audits: [SafetyAudit]
    @Binding var includeDemos: Bool

    private var summary: ObservationSummary {
        ObservationSummaryBuilder.make(from: audits, includeDemos: includeDemos)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            HStack(spacing: 10) {
                summaryStat("Shown", "\(summary.includedCount)")
                summaryStat("Yours", "\(summary.userCount)")
                summaryStat("DEMO", "\(summary.demoCount)")
            }

            Toggle("Include DEMO", isOn: $includeDemos)
                .tint(AppTheme.amber)
                .font(.subheadline)

            HStack(spacing: 8) {
                ForEach(AuditSeverity.allCases) { severity in
                    VStack(spacing: 2) {
                        Text("\(summary.countsBySeverity[severity] ?? 0)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(AppTheme.navy)
                        Text(severity.rawValue)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.mutedText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if summary.mostFrequentConcerns.isEmpty {
                Text("No concerns yet")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mutedText)
            } else {
                ForEach(summary.mostFrequentConcerns) { item in
                    HStack {
                        Text(item.concern.rawValue)
                            .font(.caption)
                            .foregroundStyle(AppTheme.charcoal)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.navy)
                    }
                }
            }
        }
        .appCard()
        .animation(.snappy, value: includeDemos)
        .animation(.snappy, value: audits)
    }

    private func summaryStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(AppTheme.navy)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
