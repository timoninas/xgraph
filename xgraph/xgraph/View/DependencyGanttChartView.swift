//
//  DependencyGanttChartView.swift
//  xgraph
//
//  Created by Антон Тимонин on 19.04.2025.
//

import SwiftUI
import Charts

struct DependencyGanttChartView: View {
    
    // MARK: - Internal properties
    
    let log: LogDependencies
    
    // MARK: - Private properties
    
    private let xAxisFormat: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(1))
    
    private struct Item: Identifiable {
        let id = UUID()
        let name: String
        let start: Double
        let end: Double
        let color: Color
    }
    
    private var ganttItems: [Item] {
        guard let baseline = log.packages.map(\.startTime).min() else { return [] }
        return log.packages.map { pkg in
            Item(
                name:  pkg.name,
                start: pkg.startTime - baseline,
                end:   pkg.endTime   - baseline,
                color: pkg.type == .dynamic ? .blue : .green
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Text("Dependency Gantt Chart for \(log.fileName)")
                .font(.headline)
                .padding(.top, 8)
            
            Text("Total build time: \(String(format: "\"%.2f\"", log.totalDuration)) sec")
                .font(.footnote)
                .foregroundColor(.red)
                .padding(.bottom, 8)
        }
        .padding()
    }
    
    // MARK: - Private views
    
    private var chart: some View {
        Chart {
            ForEach(ganttItems) { item in
                BarMark(
                    xStart: .value("Start Time", item.start),
                    xEnd:   .value("End Time",   item.end),
                    y:      .value("Package",    item.name)
                )
                .foregroundStyle(item.color)
                .annotation(position: .overlay, alignment: .leading) {
                    Text(item.name)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(2)
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in AxisValueLabel() }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) {
                AxisGridLine()
                AxisValueLabel(format: xAxisFormat)
            }
        }
        .chartXAxisLabel("Время сборки (sec)")
        .frame(height: 300)
    }
}
