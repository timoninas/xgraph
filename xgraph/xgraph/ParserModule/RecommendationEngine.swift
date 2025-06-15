//
//  RecommendationEngine.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

//
//  RecommendationEngine.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import Foundation

// MARK: –‑ Public models ------------------------------------------------------

enum Vulnerability: String, CaseIterable, Hashable, Codable {
    case heavyComponent      = "Бутылочное горлышко"
    case criticalPath        = "Критический путь"
    case lowParallelism      = "Низкий коэффициент параллельности"
    case staticFanOut        = "Статический fan‑out"
    case dynamicSingleUse    = "Одиночный dynamic"
    case heavyDependency     = "Тяжёлая зависимость"
    case emptyMediator       = "Пустой посредник"
    case manySmallDeps       = "Множество мелких зависимостей"
    case longSeqPath         = "Длинный последовательный путь"
    case cyclicDeps          = "Циклические зависимости"
}

struct Recommendation: Identifiable, Hashable, Codable {
    let id = UUID()
    let type: Vulnerability
    let message: String
    let affected: [String]
    let score: Double         // взвешенный индекс (для сортировки)
}

// MARK: –‑ Engine -------------------------------------------------------------

struct RecommendationEngine {

    private let cfg = AnalyzerConfig.load()

    /// Главная точка входа
    func analyze(log: LogDependencies,
                 graph: [Target : [Dependency]]?) -> [Recommendation] {

        // --------------------------------------------------------------------
        // 0.  Пред‑вычисляем «чистое» время пакетов и удобные индексы
        // --------------------------------------------------------------------
        let gantt      = DependencyCombiner.combine(log)   // содержит selfDuration
        let selfMap    = Dictionary(uniqueKeysWithValues: gantt.map { ($0.name, $0.selfDuration) })
        let totalSelf  = gantt.reduce(0) { $0 + $1.selfDuration }  // Σ selfDuration
        let totalWall  = log.totalDuration                              // реальное «стенка‑стенка»

        // guard – если selfDuration ещё не посчитан (редкий случай)
        if totalSelf == 0 { return [] }

        var recs: [Recommendation] = []

        // --------------------------------------------------------------------
        // 1.  Бутылочное горлышко
        // --------------------------------------------------------------------
        for gi in gantt where gi.selfDuration / totalWall * 100 >= cfg.thresholds.heavyComponent {
            recs.append(.init(
                type: .heavyComponent,
                message: "Компонент «\(gi.name)» занимает "
                       + "\(String(format: "%.1f", 100 * gi.selfDuration / totalWall)) % wall‑time ― "
                       + "рассмотрите его декомпозицию или кэширование.",
                affected: [gi.name],
                score: index(for: .heavyComponent)))
        }

        // --------------------------------------------------------------------
        // 2.  Критический путь
        // --------------------------------------------------------------------
        if let cpEnd = gantt.map(\.end).max(),
           (cpEnd - (gantt.map(\.start).min() ?? 0)) / totalWall * 100
                >= cfg.thresholds.criticalPath {

            let tail = gantt.filter { $0.end == cpEnd }.map(\.name)
            recs.append(.init(
                type: .criticalPath,
                message: "Критический путь ≥ \(Int(cfg.thresholds.criticalPath)) % "
                       + "от общей длительности сборки.",
                affected: tail,
                score: index(for: .criticalPath)))
        }

        // --------------------------------------------------------------------
        // 3.  Коэффициент параллельности
        //      avgParallelism = Σ self / wall‑time
        // --------------------------------------------------------------------
        let avgParallelism = totalSelf / totalWall
        if avgParallelism < cfg.thresholds.lowParallelism {
            recs.append(.init(
                type: .lowParallelism,
                message: "Средний коэффициент параллельности всего \(String(format: "%.1f", avgParallelism)) "
                       + "(ниже порога \(Int(cfg.thresholds.lowParallelism))).",
                affected: [],
                score: index(for: .lowParallelism)))
        }

        // --------------------------------------------------------------------
        // 4.  Статический fan‑out
        // --------------------------------------------------------------------
        if let g = graph {
            g.forEach { target, deps in
                guard deps.contains(where: { $0.type == .explicit }) else { return }
                if deps.count >= Int(cfg.thresholds.staticFanOut) {
                    recs.append(.init(
                        type: .staticFanOut,
                        message: "Статическая «\(target.name)» имеет \(deps.count) потребителей.",
                        affected: [target.name],
                        score: index(for: .staticFanOut)))
                }
            }
        }

        // --------------------------------------------------------------------
        // 5.  Dynamic‑single‑use
        // --------------------------------------------------------------------
        if let g = graph {
            log.packages
               .filter { $0.type == .dynamic }
               .forEach { pkg in
                   let consumers = g.values.flatMap { $0 }
                       .filter { $0.target.name == pkg.name }.count
                   if consumers <= Int(cfg.thresholds.dynamicSingleUse) {
                       recs.append(.init(
                           type: .dynamicSingleUse,
                           message: "Динамическая «\(pkg.name)» используется единственным потребителем ― "
                                  + "можно сделать статической.",
                           affected: [pkg.name],
                           score: index(for: .dynamicSingleUse)))
                   }
               }
        }

        // --------------------------------------------------------------------
        // 6 / 8.  Множество мелких пакетов
        // --------------------------------------------------------------------
        let small = gantt.filter { $0.selfDuration / totalWall * 100
                                   < cfg.thresholds.manySmallDeps.maxDuration }
        if small.count >= cfg.thresholds.manySmallDeps.minCount {
            recs.append(.init(
                type: .manySmallDeps,
                message: "\(small.count) компонентов занимают < "
                       + "\(Int(cfg.thresholds.manySmallDeps.maxDuration)) % wall‑time каждый.",
                affected: small.map(\.name),
                score: index(for: .manySmallDeps)))
        }

        // --------------------------------------------------------------------
        // 9.  Длинный последовательный сегмент (по selfDuration)
        // --------------------------------------------------------------------
        let seq = gantt
            .sorted { $0.start < $1.start }
            .reduce(into: (prevEnd: 0.0, acc: 0.0)) { acc, gi in
                acc.acc += max(0, gi.selfDuration - max(0, acc.prevEnd - gi.start))
                acc.prevEnd = max(acc.prevEnd, gi.end)
            }.acc

        if seq / totalWall * 100 >= cfg.thresholds.longSequentialPath {
            recs.append(.init(
                type: .longSeqPath,
                message: "Последовательный участок сборки занимает "
                       + "\(String(format: "%.1f", 100 * seq / totalWall)) %.",
                affected: [],
                score: index(for: .longSeqPath)))
        }

        // --------------------------------------------------------------------
        // 10.  Циклические зависимости
        // --------------------------------------------------------------------
        if let g = graph, hasCycles(g) {
            recs.append(.init(
                type: .cyclicDeps,
                message: "Обнаружены циклические зависимости между компонентами.",
                affected: [],
                score: index(for: .cyclicDeps)))
        }

        return recs.sorted { $0.score > $1.score }
    }

    // MARK: –‑ Индексация важности ------------------------------------------

    private func index(for v: Vulnerability) -> Double {
        let w = cfg.weights
        switch v {
        case .heavyComponent:   return 25*w.cold + 15*w.incr +  3*w.link + 1*w.run
        case .criticalPath:     return 25*w.cold + 15*w.incr +  1*w.link + 1*w.run
        case .lowParallelism:   return 15*w.cold +  7*w.incr +  1*w.link + 1*w.run
        case .staticFanOut:     return  7*w.cold + 15*w.incr + 25*w.link + 3*w.run
        case .dynamicSingleUse: return  1*w.cold +  3*w.incr +  3*w.link + 15*w.run
        case .heavyDependency:  return  7*w.cold +  3*w.incr +  1*w.link + 1*w.run
        case .emptyMediator:    return  3*w.cold +  3*w.incr +  1*w.link + 1*w.run
        case .manySmallDeps:    return  3*w.cold +  7*w.incr +  7*w.link + 1*w.run
        case .longSeqPath:      return  3*w.cold +  3*w.incr +  1*w.link + 1*w.run
        case .cyclicDeps:       return  5*w.cold + 10*w.incr +  5*w.link + 2*w.run
        }
    }

    // MARK: –‑ Топология -----------------------------------------------------

    private func hasCycles(_ g: [Target:[Dependency]]) -> Bool {
        var visiting = Set<Target>()
        var visited  = Set<Target>()

        func dfs(_ t: Target) -> Bool {
            if visiting.contains(t) { return true }
            if visited.contains(t)  { return false }
            visiting.insert(t)
            defer { visiting.remove(t); visited.insert(t) }
            for d in g[t] ?? [] where dfs(d.target) { return true }
            return false
        }
        return g.keys.contains(where: dfs)
    }
}
