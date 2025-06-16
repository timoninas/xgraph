//
//  OverviewWindow.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//


//
//  OverviewWindow.swift
//  xgraph
//

import SwiftUI
import AppKit

enum OverviewWindow {

    private static var window: NSWindow?

    static func show(log: LogDependencies, manager: DerivedDataManager) {

        if let w = window { w.makeKeyAndOrderFront(nil); return }

        let root = OverviewRootView(log: log, manager: manager)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        let ctrl = NSHostingController(rootView: root)
        let win  = NSWindow(contentViewController: ctrl)
        win.title = "Обзор проекта"
        win.setContentSize(NSSize(width: 1600, height: 900))
        win.styleMask.insert([.resizable, .titled, .closable, .miniaturizable])
        win.center(); win.makeKeyAndOrderFront(nil)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                               object: win,
                                               queue: .main) { _ in window = nil }

        window = win
    }
}

private struct OverviewRootView: View {

    let log: LogDependencies
    @ObservedObject var manager: DerivedDataManager
    @StateObject private var vm: RecommendationPanelViewModel

    init(log: LogDependencies, manager: DerivedDataManager) {
        self.log     = log
        self.manager = manager
        _vm = StateObject(wrappedValue: RecommendationPanelViewModel(manager: manager))
    }

    var body: some View {
        HStack(spacing: 0) {

            // диаграмма — всегда растягивается
            CombinedDependencyGanttChartView(log: log)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // панель рекомендаций фикс. ширины
            RecommendationListView(vm: vm)
                .frame(width: 420)
        }
    }
}
