//
//  RecommendationPanelViewModel.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI
import Combine

@MainActor
final class RecommendationPanelViewModel: ObservableObject {

    // Алгоритмические и AI‑советы
    @Published private(set) var algo: [Recommendation] = []
    @Published private(set) var ai:   [Recommendation] = []

    // Состояние загрузки AI
    @Published var isAILoading     = false
    @Published var hasAIGenerated  = false

    // Текущий снимок проекта (нужен для Llama)
    private var latestLog:   LogDependencies?
    private var latestGraph: [Target:[Dependency]]?

    private let llama = LlamaRecommendationInteractor()
    private var cancellables = Set<AnyCancellable>()

    // --------------------------------------------------------------------
    ///  Подписываемся сразу на три паблишера DerivedDataManager'а
    // --------------------------------------------------------------------
    init(manager: DerivedDataManager) {

        manager.$recommendations                // 1) алгоритмические советы
            .receive(on: DispatchQueue.main)
            .assign(to: &$algo)

        manager.$parsedResults                 // 2) первый доступный лог
            .map(\.first)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.latestLog = $0 }
            .store(in: &cancellables)

        manager.$selectedDependencyGraph       // 3) граф зависимостей
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.latestGraph = $0 }
            .store(in: &cancellables)
    }

    // --------------------------------------------------------------------
    ///  Запрашиваем AI‑советы через Llama
    // --------------------------------------------------------------------
    func generateAI() {
        guard !isAILoading, !hasAIGenerated,
              let log = latestLog else { return }

        isAILoading = true
        Task {
            do {
                let res = try await llama.fetch(for: log, graph: latestGraph)
                ai             = res
                hasAIGenerated = true
            } catch {
                ai = [.init(type: .emptyMediator,
                            message: "⚠️ AI‑сервис недоступен: \(error.localizedDescription)",
                            affected: [], score: .zero)]
            }
            isAILoading = false
        }
    }
}
