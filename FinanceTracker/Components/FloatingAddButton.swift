//
//  FloatingAddButton.swift
//  Finna
//
//  56pt accent-colored circle with a plus icon. Fixed above the tab bar.
//

import SwiftUI

struct FloatingAddButton: View {
    @Environment(\.colorScheme) private var colorScheme

    var action: () -> Void

    /// A soft black shadow reads as depth in light mode but turns into a muddy
    /// halo on the near-black dark background. In dark mode tint the shadow with
    /// the accent so the button glows rather than smudges.
    private var shadowColor: Color {
        colorScheme == .dark
            ? AppTheme.Colors.accent.opacity(0.45)
            : .black.opacity(0.18)
    }

    var body: some View {
        Button {
            HapticManager.light()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.appSans(24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(AppTheme.Colors.accent)
                .clipShape(Circle())
                .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Add transaction")
    }
}

#Preview {
    FloatingAddButton(action: {})
}
