//
//  RecommendationCardView.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI

struct RecommendationCardView: View {

    let item: Recommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.type.rawValue)
                .font(.headline)

            Text(item.message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            if !item.affected.isEmpty {
                Text("Компоненты: \(item.affected.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
        )
    }
}
