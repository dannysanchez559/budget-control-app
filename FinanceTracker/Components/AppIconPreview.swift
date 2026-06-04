//
//  AppIconPreview.swift
//  Finna
//
//  Visual reference for the App Store icon design. This view is NOT shipped in
//  any screen — the actual 1024×1024 icon is exported manually from this design.
//
//  Design: solid AppTheme.accent (#3D52A0) field with a single white, minimal
//  wallet glyph centered. Clean, flat, no gradients or shadows.
//

import SwiftUI

struct AppIconPreview: View {
    /// The rendered icon size. App Store requires a 1024×1024 export.
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Solid accent background — the brand color, no gradient.
            AppTheme.Colors.accent

            // Centered white wallet symbol. Sized as a fraction of the canvas
            // so the export scales correctly at any dimension.
            Image(systemName: "wallet.pass.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.white)
                .frame(width: size * 0.46, height: size * 0.46)
        }
        .frame(width: size, height: size)
        // Continuous corner matching the iOS app-icon mask (~22.37% of side).
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
    }
}

#Preview("App Icon — 1024") {
    AppIconPreview()
        .frame(width: 256, height: 256)
        .padding()
        .background(AppTheme.Colors.background)
}
