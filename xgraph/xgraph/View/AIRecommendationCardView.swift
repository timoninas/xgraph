//
//  AIRecommendationCardView.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI

/// Градиентная карточка для AI‑советов.
struct AIRecommendationCardView: View {

    let item: Recommendation          // ← 1. item теперь `let`, не @State
    @State private var pulse = false  // анимация «дыхания»

    var body: some View {
        HStack(spacing: 14) {

            // анимированный SF‑Symbol
            Image(systemName: "sparkles")
                .font(.system(size: 30, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(.white)
                .scaleEffect(pulse ? 1.12 : 1.0)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                           value: pulse)

            // текстовый блок, полностью берёт данные из `item`
            VStack(alignment: .leading, spacing: 4) {

                // Заголовок = тип рекомендации
                Text(item.type.rawValue + " (AI)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)

                // Основное сообщение
                Text(item.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)

                // Список затронутых пакетов (если есть)
                if !item.affected.isEmpty {
                    Text("Компоненты: \(item.affected.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .onAppear { pulse = true }

        // фирменный «дышащий» градиент
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.29, green: 0.52, blue: 0.97),
                    Color(red: 0.60, green: 0.27, blue: 0.99)
                ]),
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
    }
}
