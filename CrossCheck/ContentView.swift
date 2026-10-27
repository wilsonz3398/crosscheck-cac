//
//  ContentView.swift
//  CrossCheck
//

import MapKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AuditStore

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: MapDefaults.sanFrancisco,
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapCenter = MapDefaults.sanFrancisco
    @State private var isCreatingAudit = false
    @State private var selectedAudit: SafetyAudit?
    @State private var includeDemosInSummary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    mapCard
                    newAuditButton

                    ObservationSummaryCard(
                        audits: store.audits,
                        includeDemos: $includeDemosInSummary
                    )

                    if store.audits.isEmpty {
                        emptyState
                    } else {
                        observationList
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(AppTheme.cream.ignoresSafeArea())
            .navigationTitle("CrossCheck")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Load fictional demos", systemImage: "flag") {
                            store.loadFictionalDemos()
                        }
                        if store.hasDemoAudits {
                            Button("Remove demo records", systemImage: "trash", role: .destructive) {
                                store.removeDemoAudits()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Demo options")
                }
            }
            .sheet(isPresented: $isCreatingAudit) {
                AuditEditorView(initialCoordinate: selectedCoordinate)
                    .environmentObject(store)
            }
            .sheet(item: $selectedAudit) { audit in
                AuditDetailView(auditID: audit.id)
                    .environmentObject(store)
            }
        }
        .tint(AppTheme.amber)
        .preferredColorScheme(.light)
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            MapReader { proxy in
                Map(position: $cameraPosition) {
                    ForEach(store.audits) { audit in
                        Marker(
                            audit.isDemo ? "DEMO" : audit.locationName,
                            systemImage: audit.isDemo ? "flag.fill" : "exclamationmark.triangle.fill",
                            coordinate: audit.coordinate
                        )
                        .tint(audit.isDemo ? AppTheme.amber : AppTheme.navy)
                    }

                    if let selectedCoordinate {
                        Marker("Selected", systemImage: "mappin.circle.fill", coordinate: selectedCoordinate)
                            .tint(AppTheme.amber)
                    }
                }
                .mapStyle(.standard)
                .onMapCameraChange(frequency: .onEnd) { context in
                    mapCenter = context.camera.centerCoordinate
                }
                .onTapGesture(coordinateSpace: .local) { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        selectedCoordinate = coordinate
                    }
                }
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(AppTheme.amber)
                if let selectedCoordinate {
                    Text(String(format: "%.4f, %.4f", selectedCoordinate.latitude, selectedCoordinate.longitude))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(AppTheme.navy)
                } else {
                    Text("Tap map to set location")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.mutedText)
                }
                Spacer()
                Button("Use center") {
                    selectedCoordinate = mapCenter
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .appCard(padding: 12)
    }

    private var newAuditButton: some View {
        Button {
            isCreatingAudit = true
        } label: {
            Label("New Safety Audit", systemImage: "plus.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.navy)
        .foregroundStyle(.white)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "map")
                .font(.system(size: 32))
                .foregroundStyle(AppTheme.amber)
            Text("No observations yet")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)
            Text("Set a pin, then start an audit.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .appCard()
    }

    private var observationList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved")
                .font(.headline)
                .foregroundStyle(AppTheme.navy)

            ForEach(store.audits) { audit in
                Button {
                    selectedAudit = audit
                } label: {
                    ObservationRow(audit: audit)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.snappy, value: store.audits)
    }
}

private struct ObservationRow: View {
    let audit: SafetyAudit

    var body: some View {
        let score = SafetyAuditScorer.score(audit)

        HStack(alignment: .center, spacing: 12) {
            Text("\(score.total)")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(AppTheme.navy)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(audit.locationName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.navy)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: 8)
                    if audit.isDemo {
                        DemoBadge()
                    }
                }

                HStack(spacing: 8) {
                    SeverityBadge(severity: audit.severity)
                    Text(audit.observedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedText)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel(accessibilityText(score: score))
    }

    private func accessibilityText(score: ObservationPriorityScore) -> String {
        var parts = [audit.locationName, audit.severity.rawValue, "Priority index \(score.total)"]
        if audit.isDemo { parts.append("Fictional demonstration") }
        return parts.joined(separator: ", ")
    }
}

#Preview {
    ContentView()
        .environmentObject(AuditStore())
}
