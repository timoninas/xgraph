//
//  CombinedDependencyGanttChartView.swift
//  xgraph
//
//  Created by Anton Timonin on 22.04.2025.
//

import SwiftUI
import Charts

private struct BarChart: View {
    let items:    [GanttItem]
    let domainX:  ClosedRange<Double>
    let pxPerSec: CGFloat
    let size:     CGSize
    
    @State private var tip: (item: GanttItem, p: CGPoint)?
    
    var body: some View {
        ScrollView(.horizontal) {
            Chart {
                ForEach(items) { it in
                    BarMark(
                        xStart: .value("start", it.start),
                        xEnd:   .value("end",   it.end),
                        y:      .value("pkg",   it.name)
                    )
                    .foregroundStyle(color(for: it.type))
                    .annotation(position: .overlay, alignment: .leading) {
                        let w = (it.end - it.start) * Double(pxPerSec)
                        if w > 40 {
                            Text("\(it.name)  \(String(format: "%.1f с", it.duration))")
                                .font(.caption2)
                                .padding(.horizontal, 3)
                                .padding(.vertical,   1)
                                .background(.thinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                    }
                }
            }
            .chartXScale(domain: domainX)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Color.clear
                        .contentShape(Rectangle())
                        .modifier(HoverTracker { loc in
                            updateTip(proxy: proxy, geo: geo, point: loc)
                        })
                }
            }
            .overlay(alignment: .topLeading) {
                if let t = tip {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.item.name).bold()
                        Text(String(format: "%.1f с", t.item.duration))
                    }
                    .font(.caption)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(radius: 4)
                    )
                    .offset(x: t.p.x + 8,
                            y: max(t.p.y - 40, 0))
                    .transition(.opacity)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
    
    private func updateTip(proxy: ChartProxy,
                           geo:   GeometryProxy,
                           point: CGPoint) {
        let plot = geo[proxy.plotAreaFrame]
        guard plot.contains(point) else { tip = nil; return }
        
        let lx = point.x - plot.origin.x
        let ly = point.y - plot.origin.y
        
        guard
            let xVal: Double = proxy.value(atX: lx, as: Double.self),
            let yVal: String = proxy.value(atY: ly, as: String.self),
            let hit  = items.first(where: { $0.name == yVal &&
                $0.start <= xVal && xVal <= $0.end })
        else { tip = nil; return }
        
        tip = (hit, point)
    }
    
    private func color(for t: Package.DepType) -> Color {
        switch t {
        case .staticLib: .green
        case .dynamic:   .blue
        case .unknown:   .gray
        }
    }
}

private struct HoverTracker: ViewModifier {
    let onMove: (CGPoint) -> Void
    func body(content: Content) -> some View {
        content.onContinuousHover { ph in
            switch ph {
            case .active(let p): onMove(p)
            case .ended:         onMove(.zero)
            @unknown default:    break
            }
        }
    }
}

private struct BottomAxis: View {
    let domainX:  ClosedRange<Double>
    let pxPerSec: CGFloat
    let tickStep: Double
    
    var body: some View {
        
        let ticks = Array(stride(from: domainX.lowerBound,
                                 through: domainX.upperBound,
                                 by: tickStep))
        
        ScrollView(.horizontal) {
            Chart {
                PointMark(x: .value("x", 0), y: .value("y", 0)).opacity(0)
            }
            .chartXScale(domain: domainX)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(position: .bottom, values: ticks) { ctx in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = ctx.as(Double.self) {
                            Text("\(v, specifier: "%.0f") с")
                        }
                    }
                }
            }
            .chartXAxisLabel("Время, сек")
            .frame(width: CGFloat(domainX.upperBound) * pxPerSec,
                   height: 16)
        }
    }
}

struct CombinedDependencyGanttChartView: View {
    
    let log:   LogDependencies
    let graph: [Target : [Dependency]]?
    
    var body: some View {
        
        let items = makeItems()
        let g     = geometry(for: items)
        
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Gantt-диаграмма сборки «\(log.fileName)»")
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
    private func makeItems() -> [GanttItem] {
        
        let byName = Dictionary(uniqueKeysWithValues:
                                    log.packages.map { ($0.name, $0) })
        var memo = [String: Double]()
        
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
        
        return log.packages.map { p in
            var st = Set<String>()
            let begin = start(for: p.name, stack: &st)
            return GanttItem(name: p.name,
                             start: begin,
                             end:   begin + p.duration,
                             duration: p.duration,
                             type: p.type)
        }
        .sorted { $0.start < $1.start }
    }
    
    private func geometry(for items: [GanttItem])
    -> (rowH: CGFloat, pxPerSec: CGFloat,
        contentW: CGFloat, contentH: CGFloat,
        timelineMax: Double, tick: Double)
    {
        let rowH: CGFloat = 18
        
        let timelineMax = max(log.totalDuration,
                              items.map(\.end).max() ?? 0)
        
        let pxPerSec = max(3, min(10, 1400 / CGFloat(timelineMax)))
        let contentW = CGFloat(timelineMax) * pxPerSec
        let contentH = CGFloat(items.count) * rowH
        
        let tick = niceStep(for: timelineMax / 8)
        
        return (rowH, pxPerSec, contentW, contentH, timelineMax, tick)
    }
    
    private func niceStep(for raw: Double) -> Double {
        guard raw > 0 else { return 1 }
        let p = pow(10.0, floor(log10(raw)))
        let f = raw / p
        let b: Double
        switch f {
        case ..<1.5: b = 1
        case ..<3:   b = 2
        case ..<7:   b = 5
        default:     b = 10
        }
        return b * p
    }
}
