//
//  AuditEditorView.swift
//  CrossCheck
//

import MapKit
import SwiftUI

struct AuditEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AuditStore

    let existingAudit: SafetyAudit?
    let initialCoordinate: CLLocationCoordinate2D?

    @State private var locationName: String
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var mapCenter: CLLocationCoordinate2D
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedConcerns: Set<SafetyConcern>
    @State private var severity: AuditSeverity
    @State private var notes: String
    @State private var validationMessage: String?
    @State private var showDeleteConfirm = false

    init(existingAudit: SafetyAudit? = nil, initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.existingAudit = existingAudit
        self.initialCoordinate = initialCoordinate

        let startCoordinate = existingAudit?.coordinate
            ?? initialCoordinate
            ?? MapDefaults.sanFrancisco

        _locationName = State(initialValue: existingAudit?.locationName ?? "")
        _selectedCoordinate = State(initialValue: existingAudit?.coordinate ?? initialCoordinate)
        _mapCenter = State(initialValue: startCoordinate)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: startCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        ))
        _selectedConcerns = State(initialValue: Set(existingAudit?.concerns ?? []))
        _severity = State(initialValue: existingAudit?.severity ?? .medium)
        _notes = State(initialValue: existingAudit?.notes ?? "")
    }

    private var isEditing: Bool { existingAudit != nil }

    var body: some View {
        NavigationStack {
            Form {
                locationSection
                concernSection
                severitySection
                notesSection
                scorePreviewSection

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Observation", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Observation" : "New Safety Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAudit() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Delete this observation?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let existingAudit {
                        store.delete(existingAudit)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes it from this device only.")
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.cream)
        }
        .tint(AppTheme.amber)
    }

    private var locationSection: some View {
        Section {
            TextField("Intersection or location name", text: $locationName)
                .textInputAutocapitalization(.words)

            MapReader { proxy in
                Map(position: $cameraPosition) {
                    if let selectedCoordinate {
                        Marker("Selected location", coordinate: selectedCoordinate)
                            .tint(AppTheme.amber)
                    }
                }
                .mapStyle(.standard)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onMapCameraChange(frequency: .onEnd) { context in
                    mapCenter = context.camera.centerCoordinate
                }
                .onTapGesture(coordinateSpace: .local) { position in
                    if let coordinate = proxy.convert(position, from: .local) {
                        selectedCoordinate = coordinate
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))

            HStack {
                if let selectedCoordinate {
                    Text(coordinateLabel(selectedCoordinate))
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Tap map or use center")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Use center") {
                    selectedCoordinate = mapCenter
                }
                .font(.footnote.weight(.semibold))
            }
        } header: {
            Text("Location")
        }
    }

    private var concernSection: some View {
        Section("Safety concerns") {
            ForEach(SafetyConcern.allCases) { concern in
                Toggle(isOn: concernBinding(concern)) {
                    Text(concern.rawValue)
                }
                .tint(AppTheme.amber)
            }
        }
    }

    private var severitySection: some View {
        Section("Severity") {
            Picker("Severity", selection: $severity) {
                ForEach(AuditSeverity.allCases) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var notesSection: some View {
        Section("Notes (optional)") {
            TextField("What did you observe?", text: $notes, axis: .vertical)
                .lineLimit(3...8)
        }
    }

    private var scorePreviewSection: some View {
        let preview = SafetyAuditScorer.score(
            concerns: Array(selectedConcerns),
            severity: severity
        )
        return Section {
            HStack {
                Text("Priority index")
                Spacer()
                Text("\(preview.total) / \(preview.maximum)")
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            DisclosureGroup("Factors") {
                ForEach(preview.contributions) { item in
                    HStack {
                        Text(item.label)
                        Spacer()
                        Text("+\(item.points)")
                            .monospacedDigit()
                    }
                    .font(.footnote)
                }
            }
        } header: {
            Text("Heuristic")
        } footer: {
            Text(SafetyAuditScorer.disclaimer)
        }
    }

    private func concernBinding(_ concern: SafetyConcern) -> Binding<Bool> {
        Binding(
            get: { selectedConcerns.contains(concern) },
            set: { isOn in
                if isOn {
                    selectedConcerns.insert(concern)
                } else {
                    selectedConcerns.remove(concern)
                }
            }
        )
    }

    private func saveAudit() {
        let trimmedName = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let selectedCoordinate else {
            validationMessage = "Select a location on the map before saving."
            return
        }
        guard !trimmedName.isEmpty else {
            validationMessage = "Enter an intersection or location name."
            return
        }
        guard !selectedConcerns.isEmpty else {
            validationMessage = "Select at least one safety concern."
            return
        }

        let audit = SafetyAudit(
            id: existingAudit?.id ?? UUID(),
            locationName: trimmedName,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            observedAt: existingAudit?.observedAt ?? Date(),
            concerns: SafetyConcern.allCases.filter { selectedConcerns.contains($0) },
            severity: severity,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            isDemo: existingAudit?.isDemo ?? false
        )
        store.save(audit)
        dismiss()
    }

    private func coordinateLabel(_ coordinate: CLLocationCoordinate2D) -> String {
        String(
            format: "Selected: %.5f, %.5f",
            coordinate.latitude,
            coordinate.longitude
        )
    }
}
