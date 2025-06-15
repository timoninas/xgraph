//
//  CombinedDependencyGanttChartView.swift
//  xgraph
//
//  Created by Anton Timonin on 22.04.2025.
//

import SwiftUI
import Charts

struct GanttItem: Identifiable {
    let id = UUID()
    let name: String
    let start: Double
    let end: Double
    let duration: Double
    let selfDuration: Double
    let type: Package.DepType
    let deps: Set<String>
}

private struct TargetColumn: View {
    
    // MARK: - Internal properties
    
    let items: [GanttItem]
    let rowH:  CGFloat
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items) { it in
                Text(it.name)
                    .font(.system(size: 12,
                                  weight: .regular,
                                  design: .monospaced))
                    .frame(height: rowH, alignment: .center)
            }
        }
        .padding(.trailing, 4)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct BarChart: View {
    
    // MARK: - Internal properties
    
    let items:    [GanttItem]
    let domainX:  ClosedRange<Double>
    let pxPerSec: CGFloat
    let size:     CGSize
    
    // MARK: - Private properties
    
    @State private var tip: (item: GanttItem, p: CGPoint)?
    @State private var sel:  GanttItem?
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal) {
            Chart {
                ForEach(items) { it in
                    BarMark(
                                xStart: .value("start", it.start),
                                xEnd:   .value("end",   it.end),
                                y:      .value("pkg",   it.name)
                            )
                            .foregroundStyle(color(for: it.type)
                                .opacity(highlightOpacity(for: it)))
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
            .overlay {
                if let s = sel {
                    let x0 = CGFloat(s.start) * pxPerSec
                    let x1 = CGFloat(s.end)   * pxPerSec
                    GeometryReader { geo in
                        let h = geo.size.height
                        Path { p in
                            p.move(to: .init(x: x0, y: 0))
                            p.addLine(to: .init(x: x0, y: h))
                            p.move(to: .init(x: x1, y: 0))
                            p.addLine(to: .init(x: x1, y: h))
                        }
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                if let t = tip {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.item.name).bold()
                        Text(String(format: "wall: %.1f с | self: %.1f с",
                                    t.item.duration, t.item.selfDuration))
                        Text("Линковка: \(label(for: t.item.type))")
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
    
    private func highlightOpacity(for it: GanttItem) -> Double {
        guard let base = sel else { return 1 }
        if it.id == base.id { return 1 }
        if base.deps.contains(it.name) { return 0.9 }
        return 0.25                          // остальные приглушаем
    }

    private func label(for t: Package.DepType) -> String {
        switch t {
        case .staticLib: "Статическая"
        case .dynamic:   "Динамическая"
        case .unknown:   "Неопределено"
        }
    }
    
    // MARK: - Private methods
    
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
        else {
            tip = nil
            sel = nil
            return
        }
        
        tip = (hit, point)
        sel = hit
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
    
    // MARK: - Internal properties
    
    let onMove: (CGPoint) -> Void
    
    // MARK: - Body
    
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
    
    // MARK: - Internal properties
    
    let domainX:  ClosedRange<Double>
    let pxPerSec: CGFloat
    let tickStep: Double
    
    // MARK: - Body
    
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
    
    // MARK: - Internal properties
    
    let log:   LogDependencies
    
    // MARK: - Body
    
    var body: some View {
        
        let items = DependencyCombiner.combine(log)
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
                .frame(height: min(g.contentH, geo.size.height - 40))
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
    
    private func geometry(for items: [GanttItem]) -> (rowH: CGFloat, pxPerSec: CGFloat,
                                                      contentW: CGFloat, contentH: CGFloat,
                                                      timelineMax: Double, tick: Double) {
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
