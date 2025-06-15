//
//  RecommendationWindow.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import SwiftUI
import AppKit

/// Одно окно «Рекомендации», аналогично GanttWindow
enum RecommendationWindow {

    private static var window: NSWindow?

    static func show(manager: DerivedDataManager) {

        // если уже открыто — просто активируем
        if let win = window {
            win.makeKeyAndOrderFront(nil)
            return
        }

        let root = RecommendationRootView(manager: manager)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        let controller = NSHostingController(rootView: root)

        let win = NSWindow(contentViewController: controller)
        win.title = "Рекомендации"
        win.setContentSize(NSSize(width: 540, height: 800))
        win.styleMask.insert([.resizable, .titled, .closable, .miniaturizable])
        win.center()
        win.makeKeyAndOrderFront(nil)

        // обнуляем статическую ссылку при закрытии
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                               object: win,
                                               queue: .main) { _ in
            window = nil
        }

        window = win
    }
}
