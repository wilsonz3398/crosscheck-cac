//
//  Theme.swift
//  CrossCheck
//

import SwiftUI

enum AppTheme {
    static let navy = Color(red: 0.07, green: 0.12, blue: 0.20)
    static let charcoal = Color(red: 0.14, green: 0.17, blue: 0.22)
    static let amber = Color(red: 0.91, green: 0.66, blue: 0.22)
    static let cream = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let mutedText = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let highSeverity = Color(red: 0.72, green: 0.28, blue: 0.18)
}

extension View {
    func appCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.navy.opacity(0.08), radius: 10, y: 3)
    }
}

struct DemoBadge: View {
    var body: some View {
        Text("DEMO")
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.amber.opacity(0.22))
            .foregroundStyle(AppTheme.navy)
            .clipShape(Capsule())
            .accessibilityLabel("Fictional demonstration")
    }
}

struct SeverityBadge: View {
    let severity: AuditSeverity

    var body: some View {
        Text(severity.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch severity {
        case .low: AppTheme.mutedText
        case .medium: AppTheme.charcoal
        case .high: AppTheme.highSeverity
        }
    }
}
