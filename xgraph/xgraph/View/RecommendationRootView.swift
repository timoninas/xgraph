//
//  RecommendationRootView.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI

struct RecommendationRootView: View {

    @ObservedObject private var manager: DerivedDataManager
    @StateObject  private var vm:       RecommendationPanelViewModel

    init(manager: DerivedDataManager) {
        _manager = ObservedObject(wrappedValue: manager)
        _vm      = StateObject(wrappedValue: RecommendationPanelViewModel(manager: manager))
    }

    var body: some View {
        RecommendationListView(vm: vm)
            .padding()
    }
}
