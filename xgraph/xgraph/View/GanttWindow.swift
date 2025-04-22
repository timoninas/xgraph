//
//  GanttWindow.swift
//  xgraph
//
//  Created by Anton Timonin on 22.04.2025.
//

import SwiftUI
import AppKit

final class GanttWindow {

    private static var windows: [NSWindow] = []

    static func show(for log: LogDependencies,
                     graph: [Target : [Dependency]]?) {

        if let existing = windows.first(where: { $0.identifier?.rawValue == log.id.uuidString }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let root = CombinedDependencyGanttChartView(log: log, graph: graph)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        let controller = NSHostingController(rootView: root)

        let win = NSWindow(contentViewController: controller)
        win.title = "Gantt – \(log.fileName)"
        win.setContentSize(NSSize(width: 1600, height: 1000))
        win.styleMask.insert([.resizable, .titled, .closable, .miniaturizable])
        win.identifier = NSUserInterfaceItemIdentifier(log.id.uuidString)
        win.center()
        win.makeKeyAndOrderFront(nil)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification,
                                               object: win,
                                               queue: .main) { _ in
            windows.removeAll { $0 == win }
        }

        windows.append(win)
    }
}
