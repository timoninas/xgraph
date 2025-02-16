<p align="center">
  <img src="images/xgraphIcon.png" alt="xgraph-logo" width="160">
</p>

# Xgraph

Курсовой проект на тему: Утилита для анализа и эврестических рекомендация для многокомпонентных (многомодульных) приложений на Xcode, Swift

---

## О проекте

`Xgraph` — это утилита для **macOS**, которая анализирует Derived Data и предоставляет:

- Строит **Gantt-диаграмму** со временем сборки проекта и каждого модуля;
- Строит диаграмму связанности проекта
- Подсвечивает тип линковки (static / dynamic / unknown);
- Показывает граф зависимостей между таргетами;
- Формирует рекомендации по улучшению сборки проекта, перекомпоновки связей компонентов в проекте, сокращению критического пути сборки

---

## Стек технологий

| Категория       | Технологии                                               |
| --------------- | -------------------------------------------------------- |
| Язык / версии   | **Swift 5**, Swift Concurrency                           |
| Архитектура     | `MVVM`                                                   |
| UI-фреймворки   | **SwiftUI**, **AppKit**                                  |
| Реактивность    | **Combine**                                              |
| Работа с логами | Собственный парсер `.xcactivitylog` + `target-graph.txt` |
| Компрессия      | **Gzip** (SPM-пакет)                                     |
| Тесты           | Unit-tests, Snapshot-tests, UI-tests                     |
| Сборщик         | Xcodeproj, **Swift Package Manager (SPM)**               |

---

## Минимальные требования

- **MacOS 15+** (для запуска GUI)
- Распакованные логи из **Xcode 16** (`iOS 18+`, `iPadOS 18+`, `tvOS 18+`, `watchOS 11+`, `visionOS 2+`)
- **Xcode CLI Tools** 16.0+

---

## Запуск проекта

```bash
# Загрузка репозитория
git clone https://github.com/your-org/Xgraph.git
cd Xgraph

# Подгрузка swift-пакетов
xcodebuild -resolvePackageDependencies -workspace xgraph.xcworkspace -scheme xgraph -quiet

# Сборка бинарного файла
xcodebuild -workspace xgraph.xcworkspace -scheme xgraph -configuration Release -destination 'generic/platform=macOS' -quiet build

# Переход в директорию с приложением
open -R "$(ls -td ~/Library/Developer/Xcode/DerivedData/xgraph-*/Build/Products/Release/xgraph.app 2>/dev/null | head -n 1)"
```

---

## Макеты

// MARK:- TODO

---

## Разработчик

[Антон Тимонин](https://github.com/timoninas)
