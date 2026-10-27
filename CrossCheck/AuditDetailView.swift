//
//  AuditDetailView.swift
//  CrossCheck
//

import MapKit
import SwiftUI

struct AuditDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AuditStore

    let auditID: UUID

    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    private var audit: SafetyAudit? {
        store.audit(id: auditID)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let audit {
                    detailContent(audit)
                } else {
                    ProgressView()
                        .onAppear { dismiss() }
                }
            }
            .navigationTitle("Observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if let audit {
                    ToolbarItemGroup(placement: .primaryAction) {
                        ShareLink(
                            item: AuditReport.text(for: audit),
                            subject: Text(AuditReport.shareSubject(for: audit))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Share report")

                        Button("Edit") { isEditing = true }
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                if let audit {
                    AuditEditorView(existingAudit: audit)
                        .environmentObject(store)
                }
            }
            .alert("Delete this observation?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let audit {
                        store.delete(audit)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes it from this device only.")
            }
            .onChange(of: store.audits) { _, _ in
                if store.audit(id: auditID) == nil {
                    dismiss()
                }
            }
        }
        .tint(AppTheme.amber)
    }

    private func detailContent(_ audit: SafetyAudit) -> some View {
        let score = SafetyAuditScorer.score(audit)

        return ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header(audit)
                mapCard(audit)
                facts(audit)
                concerns(audit)
                if !audit.notes.isEmpty {
                    notes(audit)
                }
                scoreCard(score)

                ShareLink(
                    item: AuditReport.text(for: audit),
                    subject: Text(AuditReport.shareSubject(for: audit))
                ) {
                    Label("Share Report", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.navy)

                Button("Delete", role: .destructive) {
                    showDeleteConfirm = true
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(AppTheme.cream.ignoresSafeArea())
    }

    private func header(_ audit: SafetyAudit) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(audit.locationName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
            Spacer()
            if audit.isDemo {
                DemoBadge()
            }
        }
    }

    private func mapCard(_ audit: SafetyAudit) -> some View {
        Map(position: .constant(.region(
            MKCoordinateRegion(
                center: audit.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        ))) {
            Marker(
                audit.isDemo ? "DEMO" : audit.locationName,
                systemImage: audit.isDemo ? "flag.fill" : "exclamationmark.triangle.fill",
                coordinate: audit.coordinate
            )
            .tint(audit.isDemo ? AppTheme.amber : AppTheme.navy)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .disabled(true)
    }

    private func facts(_ audit: SafetyAudit) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(audit.observedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.navy)
                Text(String(format: "%.4f, %.4f", audit.latitude, audit.longitude))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.mutedText)
            }
            Spacer()
            SeverityBadge(severity: audit.severity)
        }
        .appCard()
    }

    private func concerns(_ audit: SafetyAudit) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Concerns")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
            FlowConcerns(concerns: audit.concerns)
        }
        .appCard()
    }

    private func notes(_ audit: SafetyAudit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.navy)
            Text(audit.notes)
                .foregroundStyle(AppTheme.charcoal)
        }
        .appCard()
    }

    private func scoreCard(_ score: ObservationPriorityScore) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Priority index")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.navy)
                Spacer()
                Text("\(score.total)")
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(AppTheme.navy)
                Text("/ \(score.maximum)")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.mutedText)
            }

            ForEach(score.contributions) { item in
                HStack {
                    Text(item.label)
                    Spacer()
                    Text("+\(item.points)")
                        .fontWeight(.semibold)
                        .monospacedDigit()
                }
                .font(.footnote)
                .foregroundStyle(AppTheme.charcoal)
            }

            Text(score.disclaimer)
                .font(.caption2)
                .foregroundStyle(AppTheme.mutedText)
        }
        .appCard()
    }
}

private struct FlowConcerns: View {
    let concerns: [SafetyConcern]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(concerns) { concern in
                Text(concern.rawValue)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.cream)
                    .foregroundStyle(AppTheme.navy)
                    .clipShape(Capsule())
            }
        }
    }
}
