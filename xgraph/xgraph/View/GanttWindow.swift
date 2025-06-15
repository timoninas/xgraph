//
//  GanttWindow.swift
//  xgraph
//
//  Created by Anton Timonin on 22.04.2025.
//

import SwiftUI
import AppKit

final class DependencyCombiner {
    
    static func combine(_ logs: LogDependencies) -> [GanttItem] {
        let byName = Dictionary(uniqueKeysWithValues: logs.packages.map { ($0.name, $0) })
        var memo = [String: Double]()
        var selfMemo = [String: Double]()
        
        func selfDuration(for name: String) -> Double {
            if let cached = selfMemo[name] { return cached }
            guard let pkg = byName[name] else { return 0 }

            let maxDepDur = pkg.dependencies
                .filter { $0 != name }
                .compactMap { byName[$0]?.duration }
                .max() ?? 0

            let value = max(pkg.duration - maxDepDur, 0)
            selfMemo[name] = value
            return value
        }
        
        func start(for name: String, stack: inout Set<String>) -> Double {
            if let c = memo[name] { return c }
            guard let pkg = byName[name] else { return 0 }
            guard stack.insert(name).inserted else { return 0 }
            
            var s: Double = 0
            for d in pkg.dependencies {
                var st = stack
                let depStart = start(for: d, stack: &st)
                let depDur   = byName[d]?.duration ?? 0
                s = max(s, depStart + depDur)
            }
            stack.remove(name)
            memo[name] = s
            return s
        }
        
        return logs.packages.map { p in
            var st = Set<String>()
            let begin = start(for: p.name, stack: &st)
            let selfDuration = selfDuration(for: p.name)
            return GanttItem(name: p.name,
                             start: begin,
                             end:   begin + p.duration,
                             duration: p.duration,
                             selfDuration: selfDuration,
                             type: p.type,
                             deps: p.dependencies)
        }
        .sorted { $0.start < $1.start }
    }
}

final class GanttWindow {

    private static var windows: [NSWindow] = []

    static func show(for log: LogDependencies) {

        if let existing = windows.first(where: { $0.identifier?.rawValue == log.id.uuidString }) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let root = CombinedDependencyGanttChartView(log: log)
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
