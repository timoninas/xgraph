//
//  LlamaMessage.swift
//  xgraph
//
//  Created by Антон Тимонин on 15.06.2025.
//

import Foundation

// MARK: –‑ DTO ↔ Ollama -------------------------------------------------------

/// Формат сообщения для Ollama / llama.cpp REST‑API
private struct LlamaMessage: Codable {
    let role: String   // "system" | "user" | "assistant"
    let content: String
}

/// Запрос `POST /api/chat`
private struct LlamaChatRequest: Encodable {
    let model: String = "llama3.2"
    let messages: [LlamaMessage]
    let stream: Bool = false
    let options: Options
    
    struct Options: Encodable {
        let temperature: Double
        let top_p: Double
    }
}

/// Один ответ при `stream:false`
private struct LlamaChatResponse: Decodable {
    struct Inner: Decodable { let content: String }
    let message: Inner
}

/// JSON, который Llama должна вернуть (строгий контракт)
private struct LlamaPayload: Decodable {
    let recommendations: [Item]

    struct Item: Decodable {
        let type: String
        let message: String
        let affected: [String]
        let score: Double
    }
}

// MARK: –‑ Интерактор ---------------------------------------------------------

/// Отправляет структуру проекта в llama 3.2 и получает рекомендации
final class LlamaRecommendationInteractor {

    private let apiURL = URL(string: "http://127.0.0.1:11434/api/chat")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /// Главный публичный метод
    func fetch(for log: LogDependencies,
               graph: [Target : [Dependency]]?) async throws -> [Recommendation] {

        // 1. Формируем JSON‑описание проекта (минимально необходимое)
        let projectJSON = try encoder.encode(ProjectSnapshot(log: log, graph: graph))
        let projectString = String(decoding: projectJSON, as: UTF8.self)

        // 2. Собираем промпт
        let prompt = Self.buildPrompt(with: projectString)

        let lamaRequest = LlamaChatRequest(messages: [
            .init(role: "system", content: Self.systemPrompt),
            .init(role: "user",   content: prompt)
        ],
                                           options: LlamaChatRequest.Options(temperature: 0, top_p: 0))
        let reqBody = try encoder.encode(lamaRequest)

        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.httpBody   = reqBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Отправляем запрос
        let (data, response) = try await URLSession.shared.data(for: request)

        print()
        // 4. Парсим ответ
        let outer = try decoder.decode(LlamaChatResponse.self, from: data)
        guard let innerData = outer.message.content.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        let payload = try decoder.decode(LlamaPayload.self, from: innerData)

        // 5. Маппим в модель UI
        return payload.recommendations.compactMap(\.swiftModel)
    }

    // MARK: –‑ Формирование промпта -----------------------------------------

    private static let systemPrompt =
    """
    Ты эксперт по модульной архитектуре iOS/macOS.
    ПРАВИЛА:
    1. Отвечай ТОЛЬКО валидным JSON‑объектом, без ``` , текста и пояснений.
    2. Ключ верхнего уровня: "recommendations".
    3. Любой иной вывод недопустим — верни пустой объект {}.

    Формат одного элемента:
    {
      "type": "heavyComponent",
      "message": "Компонент Foo занимает 23 % времени — выделите его на модули.",
      "affected": ["Foo"],
      "score": 87.5
    }
    
    1. Собери с свяжи все зависимости, которые тебе поступили в проекте
    2. Посчитай количество зависимостей всего
    3. -
    4. Тебе нужно сформировать рекомендации полученные по проекту
    
    1. 

    Говори строго на русском.
    """

    /// Полный юзер‑промпт
    private static func buildPrompt(with projectJSON: String) -> String {
        """
            ### ПРИМЕР
                ВХОД:
                {"components":[{"name":"A","selfDuration":12,"deps":["B"]},{"name":"B","selfDuration":1,"deps":[]}]}

                ВЫХОД:
                {"recommendations":[
                  {"type":"manySmallDeps","message":"Компонент B занимает <1 % времени — объедините с A.","affected":["B"],"score":45}
                ]}

                ### ПРОЕКТ
                selfDuration - время потраченное на сборку конкретного модуля
                deps - зависимости модуля. Это названия зависимостей от которых зависит модуль с названием name. По ним можно получить связи всего проекта
                Этот проект представлен в json формате приложенным тебе далее:
                \(projectJSON)
            """
    }
}

// MARK: –‑ Сериализация структуры проекта ------------------------------------

/// Упрощённый снимок проекта, который понимает Llama
private struct ProjectSnapshot: Encodable {

    struct Node: Encodable {
        let name: String
        let selfDuration: Double
        let deps: [String]
    }

    let components: [Node]

    init(log: LogDependencies, graph: [Target : [Dependency]]?) {
        var map: [String : [String]] = [:]
        graph?.forEach { map[$0.key.name] = $0.value.map { $0.target.name } }

        components = log.packages.map { pkg in
            Node(name: pkg.name,
                 selfDuration: pkg.selfDuration,
                 deps: map[pkg.name] ?? [])
        }
    }
}

// MARK: –‑ helper -------------------------------------------------------------

private extension LlamaPayload.Item {
    var swiftModel: Recommendation? {
        guard let v = Vulnerability(rawValue: type) else { return nil }
        return Recommendation(type: v,
                              message: message,
                              affected: affected,
                              score: score)
    }
}
