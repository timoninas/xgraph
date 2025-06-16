//
//  MainView.swift
//  xgraph
//
//  Created by Anton Timonin on 13.04.2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct MainView: View {

    // MARK: - State

    @StateObject private var manager = DerivedDataManager()
    @State private var selectedLog: URL?
    @State private var activeLog:  LogDependencies?

    @State private var isShowingOpen = false      // NSOpenPanel

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .short; f.timeStyle = .short; return f
    }()

    // MARK: - View body

    var body: some View {
        VStack(spacing: 24) {

            // ────────────────── DerivedData Drop / Click ──────────────────
            DropArea {
                manager.processDerivedData(directory: $0)
            } onClick: {
                isShowingOpen = true                 // NSOpenPanel
            }
            .frame(height: 120)
//            .overlay(Group {
//                if manager.selectedDependencyGraph != nil {
//                    Text("✓ Данные загружены").font(.headline)
//                }
//            })

            // ────────────────── Список логов ──────────────────
            if !manager.xcactivityLogFiles.isEmpty {
                Text("Выберите лог сборки (.xcactivitylog)")
                    .font(.subheadline.bold())

                List(manager.xcactivityLogFiles, id: \.self) { url in
                    Button {
                        self.selectedLog = url
                        manager.parseLogs(urls: [url])
                    } label: {
                        HStack {
                            Text(url.lastPathComponent)
                            Spacer()
                            if
                              let d = (try? FileManager.default.attributesOfItem(atPath: url.path)[.creationDate])
                                as? Date {
                                Text(d, formatter: dateFormatter).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }

            // ────────────────── Лоадер парсинга ──────────────────
            if manager.isParsingActivityLogs {
                ProgressView("Парсинг лога…")
                    .progressViewStyle(.circular)
                    .padding()
            }

            // ────────────────── Кнопка «Открыть обзор» ──────────────────
            if let log = activeLog {
                Button {
                    OverviewWindow.show(log: log, manager: manager)
                } label: {
                    Label("Открыть обзор проекта", systemImage: "rectangle.and.paperclip")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }

            Spacer()
        }
        .padding(32)
        .frame(minWidth: 600, minHeight: 720)
        .onChange(of: manager.parsedResults) { activeLog = $0.first }
        .fileImporter(isPresented: $isShowingOpen,
                      allowedContentTypes: [.folder]) { res in
            switch res {
            case .success(let url):
                            guard url.startAccessingSecurityScopedResource() else {
                                 return
                            }
                manager.processDerivedData(directory: url)
            case .failure(let failure):
                print()
            }

//            if case .success(let url) = res { manager.processDerivedData(directory: url) }
        }
        .alert("Ошибка",
               isPresented: Binding(
                   get: { manager.errorMessage != nil },
                   set: { _ in manager.errorMessage = nil })) {
            Button("OK", role: .cancel) { manager.errorMessage = nil }
        } message: { Text(manager.errorMessage ?? "") }
    }
}

// MARK: - Красивый drop‑area + click support

private struct DropArea: View {

    var onDrop: (URL) -> Void
    var onClick: () -> Void

    @State private var isTargeted = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isTargeted ? Color.accentColor : .secondary,
                        style: StrokeStyle(lineWidth: 2, dash: [6]))
            VStack(spacing: 8) {
                Image(systemName: "tray.and.arrow.down")
                    .font(.system(size: 28))
                Text("Перетащите папку DerivedData\nили нажмите, чтобы выбрать")
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { onClick() }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { prov in
            for p in prov {
                _ = p.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { data, _ in
                    guard
                      let d = data as? Data,
                      let url = URL(dataRepresentation: d, relativeTo: nil)
                    else { return }
                    var dir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &dir),
                       dir.boolValue { DispatchQueue.main.async { onDrop(url) } }
                }
            }
            return true
        }
    }
}
