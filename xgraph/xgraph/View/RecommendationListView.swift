//
//  RecommendationListView.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI

struct RecommendationListView: View {

    @ObservedObject var vm: RecommendationPanelViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Text("Рекомендации")
                .font(.title3.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {

                    // AI‑блок
                    Group {
                        if vm.hasAIGenerated {
                            ForEach(vm.ai) { AIRecommendationCardView(item: $0) }
                        } else {
                            AIGenerateButton(isLoading: vm.isAILoading) {
                                vm.generateAI()           // ← всего одна строка
                            }
                        }
                    }

                    // Алгоритмические карточки
                    if vm.algo.isEmpty {
                        RecommendationCardView(
                            item: .init(type: .emptyMediator,
                                        message: "Уязвимостей не обнаружено 🎉",
                                        affected: [], score: .zero))
                    } else {
                        ForEach(vm.algo) { RecommendationCardView(item: $0) }
                    }
                }
                .padding(14)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
