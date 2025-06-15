//
//  DependencyListView.swift
//  xgraph
//
//  Created by Антон Тимонин on 14.04.2025.
//

import SwiftUI

struct DependencyListView: View {
    
    // MARK: - Internal properties
    
    let results: [LogDependencies]
    
    // MARK: - Body

    var body: some View {
        List {
            ForEach(results) { log in
                DisclosureGroup(log.fileName) {
                    Text("Project total time: \(String(format: "%.2f", log.totalDuration)) sec")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 4)

                    ForEach(log.packages) { p in
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: icon(for: p.type))
                                    .foregroundColor(color(for: p.type))
                                Text(p.name)
                                Spacer()
                                Text(label(for: p.type))
                                    .foregroundColor(color(for: p.type))
                            }
                            Text("""
                            Σ \(p.duration) s  •  self \(p.selfDuration) s
                            """)
                                .font(.caption)
                                .foregroundColor(.gray)

                            if !p.dependencies.isEmpty {
                                Text("Depends on: \(p.dependencies.sorted().joined(separator: ", "))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .font(.headline)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
    
    // MARK: - Private methods

    private func icon(for t: Package.DepType) -> String {
        switch t {
        case .dynamic:   return "link"
        case .staticLib: return "cube.fill"
        case .unknown:   return "questionmark"
        }
    }
    private func label(for t: Package.DepType) -> String {
        switch t {
        case .dynamic:   return "Dynamic"
        case .staticLib: return "Static"
        case .unknown:   return "Unknown"
        }
    }
    private func color(for t: Package.DepType) -> Color {
        switch t {
        case .dynamic:   return .blue
        case .staticLib: return .green
        case .unknown:   return .gray
        }
    }
}
