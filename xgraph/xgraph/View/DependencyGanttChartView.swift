//
//  DependencyGanttChartView.swift
//  xgraph
//
//  Created by Антон Тимонин on 19.04.2025.
//

import SwiftUI
import Charts

struct DependencyGanttChartView: View {
    let log: LogDependencies
    
    private let xAxisFormat: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(1))
    
    var body: some View {
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
    
    private struct Item: Identifiable {
        let id = UUID()
        let name: String
        let start: Double
        let end: Double
        let color: Color
    }
}
