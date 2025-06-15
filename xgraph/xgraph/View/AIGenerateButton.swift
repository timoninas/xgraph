//
//  AIGenerateButton.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//


import SwiftUI

struct AIGenerateButton: View {

    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [Color(red: 0.26, green: 0.53, blue: 1.0),
                                 Color(red: 0.60, green: 0.33, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing)
                    )
                    .frame(height: 52)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.title3.weight(.semibold))
                        Text("Сгенерировать AI‑советы")
                            .font(.headline)
                            .textCase(.none)
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .disabled(isLoading)
    }
}