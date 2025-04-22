//
//  CombinedDependencyGanttChartView.swift
//  xgraph
//
//  Created by Anton Timonin on 22.04.2025.
//

import SwiftUI
import Charts

struct CombinedDependencyGanttChartView: View {

    let log:   LogDependencies
    let graph: [Target : [Dependency]]?

    var body: some View {

        let items = makeItems()
        let g = geometry(for: items)

        VStack(alignment: .leading, spacing: 12) {

            Text("Gantt-диаграмма «\(log.fileName)»")
                .font(.headline)

            GeometryReader { geo in
                ScrollView(.vertical) {
                    HStack(alignment: .top, spacing: 0) {

                        TargetColumn(items: items, rowH: g.rowH)
                            .frame(minWidth: 150, alignment: .leading)

                        BarChart(items: items,
                                 domainX: 0...g.timelineMax,
                                 pxPerSec: g.pxPerSec,
                                 size: CGSize(width: g.contentW,
                                              height: g.contentH))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: min(g.contentH,
                                   geo.size.height - 40))
            }

            BottomAxis(domainX: 0...g.timelineMax,
                       pxPerSec: g.pxPerSec,
                       tickStep: g.tick)

            Text("Σ \(String(format: "%.2f", log.totalDuration)) сек")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
