//
//  ActivityLogReader.swift
//  xgraph
//
//  Created by Антон Тимонин on 01.04.2025.
//

import Foundation

/// Types of build step
public enum BuildStepType: String, Encodable {
    /// Root step
    case main

    /// Target step
    case target

    /// A step that belongs to a target, the type of it is shown by `DetailStepType`
    case detail
}

/// Categories for different kind of build steps
public enum DetailStepType: String, Encodable {

    /// clang compilation step
    case cCompilation

    /// swift compilation step
    case swiftCompilation

    /// Build phase shell script execution
    case scriptExecution

    /// Libtool was used to create a static library
    case createStaticLibrary

    /// Linking of a library
    case linker

    /// Swift Runtime was copied
    case copySwiftLibs

    /// Asset's catalog compilation
    case compileAssetsCatalog

    /// Storyboard compilation
    case compileStoryboard

    /// Auxiliary file
    case writeAuxiliaryFile

    /// Storyboard linked
    case linkStoryboards

    /// Resource file was copied
    case copyResourceFile

    /// Swift Module was merged
    case mergeSwiftModule

    /// Xib file compilation
    case XIBCompilation

    /// With xcodebuild, swift files compilation appear aggregated
    case swiftAggregatedCompilation

    /// Precompile Bridging header
    case precompileBridgingHeader

    /// Non categorized step
    case other

    /// For steps that are not a detail step
    case none

    /// Validate watch, extensions binaries
    case validateEmbeddedBinary

    /// Validate app
    case validate

    // swiftlint:disable:next cyclomatic_complexity
    public static func getDetailType(signature: String) -> DetailStepType {
        switch signature {
        case Prefix("CompileC "):
            return .cCompilation
        case Prefix("CompileSwift "):
            return .swiftCompilation
        case Prefix("Ld "):
            return .linker
        case Prefix("PhaseScriptExecution "):
            return .scriptExecution
        case Prefix("Libtool "):
            return .createStaticLibrary
        case Prefix("CopySwiftLibs "):
            return .copySwiftLibs
        case Prefix("CompileAssetCatalog"):
            return .compileAssetsCatalog
        case Prefix("CompileStoryboard "):
            return .compileStoryboard
        case Prefix("WriteAuxiliaryFile "):
            return .writeAuxiliaryFile
        case Prefix("LinkStoryboards "):
            return .linkStoryboards
        case Prefix("CpResource "):
            return .copyResourceFile
        case Prefix("MergeSwiftModule "):
            return .mergeSwiftModule
        case Prefix("CompileXIB "):
            return .XIBCompilation
        case Prefix("CompileSwiftSources "):
            return .swiftAggregatedCompilation
        case Prefix("PrecompileSwiftBridgingHeader "):
            return .precompileBridgingHeader
        case Prefix("ValidateEmbeddedBinary "):
            return .validateEmbeddedBinary
        case Prefix("Validate "):
            return .validate
        default:
            return .other
        }
    }
}

import Foundation

/// Wrap the statistics data produced by ld64 linker (-print_statistics)
public class LinkerStatistics: Encodable, Equatable {
    
    public static func == (lhs: LinkerStatistics, rhs: LinkerStatistics) -> Bool {
        lhs.totalMS == rhs.totalMS
    }
    
    public let totalMS: Double

    public let optionParsingMS: Double
    public let optionParsingPercent: Double

    public let objectFileProcessingMS: Double
    public let objectFileProcessingPercent: Double

    public let resolveSymbolsMS: Double
    public let resolveSymbolsPercent: Double

    public let buildAtomListMS: Double
    public let buildAtomListPercent: Double

    public let runPassesMS: Double
    public let runPassesPercent: Double

    public let writeOutputMS: Double
    public let writeOutputPercent: Double

    public let pageins: Int
    public let pageouts: Int
    public let faults: Int

    public let objectFiles: Int
    public let objectFilesBytes: Int

    public let archiveFiles: Int
    public let archiveFilesBytes: Int

    public let dylibFiles: Int
    public let wroteOutputFileBytes: Int

    public init(totalMS: Double,
                optionParsingMS: Double,
                optionParsingPercent: Double,
                objectFileProcessingMS: Double,
                objectFileProcessingPercent: Double,
                resolveSymbolsMS: Double,
                resolveSymbolsPercent: Double,
                buildAtomListMS: Double,
                buildAtomListPercent: Double,
                runPassesMS: Double,
                runPassesPercent: Double,
                writeOutputMS: Double,
                writeOutputPercent: Double,
                pageins: Int,
                pageouts: Int,
                faults: Int,
                objectFiles: Int,
                objectFilesBytes: Int,
                archiveFiles: Int,
                archiveFilesBytes: Int,
                dylibFiles: Int,
                wroteOutputFileBytes: Int) {
        self.totalMS = totalMS
        self.optionParsingMS = optionParsingMS
        self.optionParsingPercent = optionParsingPercent
        self.objectFileProcessingMS = objectFileProcessingMS
        self.objectFileProcessingPercent = objectFileProcessingPercent
        self.resolveSymbolsMS = resolveSymbolsMS
        self.resolveSymbolsPercent = resolveSymbolsPercent
        self.buildAtomListMS = buildAtomListMS
        self.buildAtomListPercent = buildAtomListPercent
        self.runPassesMS = runPassesMS
        self.runPassesPercent = runPassesPercent
        self.writeOutputMS = writeOutputMS
        self.writeOutputPercent = writeOutputPercent
        self.pageins = pageins
        self.pageouts = pageouts
        self.faults = faults
        self.objectFiles = objectFiles
        self.objectFilesBytes = objectFilesBytes
        self.archiveFiles = archiveFiles
        self.archiveFilesBytes = archiveFilesBytes
        self.dylibFiles = dylibFiles
        self.wroteOutputFileBytes = wroteOutputFileBytes
    }

}


/// Represents a Step in the BuildLog
public struct BuildStep: Encodable, Equatable {

    /// The type of the step
    public let type: BuildStepType

    /// The name of the machine as determined by `MachineNameReader`
    public let machineName: String

    /// The unique identifier of the build
    public let buildIdentifier: String

    /// The identifier of the step
    public let identifier: String

    /// The identifier of the parent step
    public let parentIdentifier: String

    /// Value taken from `IDEActivityLogSection.domainType`
    /// It contains values that can be used to identify the type of the step.
    /// For example: `com.apple.dt.IDE.BuildLogSection` or `Xcode.IDEActivityLogDomainType.target.product-type.target`
    public let domain: String

    /// The title of the Step <br>
    /// In steps of type BuildStepType.detail this contains the file that was compiled
    public let title: String

    /// The signature of the Step. This may contain more detail than the Title
    /// In steps of type BuildStepType.detail this contains more information about the compilation
    public let signature: String

    /// The start date of the step represented in the format ISO8601
    public let startDate: String

    /// The start date of the step represented in the format ISO8601
    public let endDate: String

    /// The timestap in which the step started represented as Unix epoch <br>
    /// - For steps of type BuildStepType.main this is the date in which the build started
    /// - Some subSteps may have a startTimestamp before the main's startTimestamp.
    /// That behaviour has been found in steps of `DetailStepType.copyResourceFile`.
    /// Probably meaning that the file was cached
    public let startTimestamp: Double

    /// The timestap in which the step ended represented as Unix epoch
    /// For steps of type BuildStepType.main this is the date in which the build ended
    public let endTimestamp: Double

    /// The number of seconds the step lasted.
    /// For steps of type BuildStepType.main this is the total duration of the build.
    public let duration: Double

    /// For builds of type
    public let detailStepType: DetailStepType

    /// The status of the build.
    /// Examples: succeeded, failed
    public let buildStatus: String

    /// The Xcode's schema executed
    public let schema: String

    /// The `BuildStep`s that belong to this step.
    /// Those subSteps will have this step `identifier` as their `parentIdentifier`
    public var subSteps = [BuildStep]()

    /// The number of warnings found in this step. <br>
    /// - For `BuildStep`s of type `BuildStepType.main` is the total number of warnings of the project
    /// - For `BuildStep`s of type `target` is the total number of warnings in its subSteps.
    public var warningCount: Int

    /// The number of errors found in this step. <br>
    /// - For `BuildStep`s of type `BuildStepType.main` is the total number of errors of the project
    /// - For `BuildStep`s of type `target` is the total number of errors in its subSteps.
    public var errorCount: Int

    /// Only used for compilation steps.
    /// It could be arm64, armv7, and so on
    public let architecture: String

    /// URL of the document in a build of type `.detail`
    public let documentURL: String

    /// The warnings found in this step
    public let warnings: [Notice]?

    /// The errors found in this step
    public let errors: [Notice]?

    /// Notes found in this step
    public let notes: [Notice]?

    /// Swift function's compilation times
    /// If the project was compiled with the swift flags `-Xfrontend -debug-time-function-bodies`
    /// This field will be populated
    public var swiftFunctionTimes: [SwiftFunctionTime]?

    /// Swift function's compilation times
    /// If the project was compiled with the swift flags `-Xfrontend -debug-time-expression-type-checking`
    /// This field will be populated
    public var swiftTypeCheckTimes: [SwiftTypeCheck]?

    /// Indicated if the step was actually processed / compiled or just fetched from Xcode's cache.
    /// In a compilation step this will be false only if the file was actually compiled.
    /// in a `target` or `main` step it will be false if at least one sub step wasn't fetched from cache.
    public let fetchedFromCache: Bool

    /// Actual compilation end time of the Step. With the new Build System, sometimes linking happens minutes
    /// after compilation finishes. This is specially visible in Targets, where the files can be compiled
    /// in seconds but the linking being done a couple of minutes after.
    public var compilationEndTimestamp: Double

    /// Actual compilation time of the Step. For Targets, this can be less than the `buildTime`
    /// For steps that are't compilation steps such as `.scriptExecution` this will be 0
    public var compilationDuration: Double

    /// Clang's time trace file path
    /// If the project was compiled with the clang flag `-ftime-trace`
    /// This field will be populated
    public var clangTimeTraceFile: String?

    /// ld64's statistics info
    /// If the project was compiled with `-Xlinker -print_statistics`
    /// This field will be populated
    public var linkerStatistics: LinkerStatistics?

    /// Public initializer
    public init(type: BuildStepType,
                machineName: String,
                buildIdentifier: String,
                identifier: String,
                parentIdentifier: String,
                domain: String,
                title: String,
                signature: String,
                startDate: String,
                endDate: String,
                startTimestamp: Double,
                endTimestamp: Double,
                duration: Double,
                detailStepType: DetailStepType,
                buildStatus: String,
                schema: String,
                subSteps: [BuildStep],
                warningCount: Int,
                errorCount: Int,
                architecture: String,
                documentURL: String,
                warnings: [Notice]?,
                errors: [Notice]?,
                notes: [Notice]?,
                swiftFunctionTimes: [SwiftFunctionTime]?,
                fetchedFromCache: Bool,
                compilationEndTimestamp: Double,
                compilationDuration: Double,
                clangTimeTraceFile: String?,
                linkerStatistics: LinkerStatistics?,
                swiftTypeCheckTimes: [SwiftTypeCheck]?
                ) {
        self.type = type
        self.machineName = machineName
        self.buildIdentifier = buildIdentifier
        self.identifier = identifier
        self.parentIdentifier = parentIdentifier
        self.domain = domain
        self.title = title
        self.signature = signature
        self.startDate = startDate
        self.endDate = endDate
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.duration = duration
        self.detailStepType = detailStepType
        self.buildStatus = buildStatus
        self.schema = schema
        self.subSteps = subSteps
        self.warningCount = warningCount
        self.errorCount = errorCount
        self.architecture = architecture
        self.documentURL = documentURL
        self.warnings = warnings
        self.errors = errors
        self.notes = notes
        self.swiftFunctionTimes = swiftFunctionTimes
        self.fetchedFromCache = fetchedFromCache
        self.compilationEndTimestamp = compilationEndTimestamp
        self.compilationDuration = compilationDuration
        self.clangTimeTraceFile = clangTimeTraceFile
        self.linkerStatistics = linkerStatistics
        self.swiftTypeCheckTimes = swiftTypeCheckTimes
    }
}

/// Extension used to flatten the three of a `BuildStep`
public extension BuildStep {

    /// Traverse a tree of BuildStep and returns a flatten Array.
    /// Used in some `BuildReporter` because is easy to handle an Array. <br>
    /// This used to be a recursive function, but it was taken too long.
    /// Since it's not recursive, it only flattens the first 3 levels of the tree.
    func flatten() -> [BuildStep] {
        var steps = [BuildStep]()
        var noSubSteps = self
        noSubSteps.subSteps = [BuildStep]()
        steps.append(noSubSteps)
        for subStep in self.subSteps {
            steps.append(contentsOf: flattenSubstep(subStep: subStep))
        }
        return steps
    }

    func flattenSubstep(subStep: BuildStep) -> [BuildStep] {
        var details = [BuildStep]()
        var noSubSteps = subStep
        noSubSteps.subSteps = [BuildStep]()
        details.append(noSubSteps)
        for detail in subStep.subSteps {
            var noSubSteps = detail
            noSubSteps.subSteps = [BuildStep]()
            details.append(noSubSteps)
            if detail.subSteps.isEmpty == false {
                details.append(contentsOf: detail.subSteps)
            }
        }
        return details
    }

    func summarize() -> BuildStep {
        var noSubSteps = self
        noSubSteps.subSteps = [BuildStep]()
        return noSubSteps
    }

    func isCompilationStep() -> Bool {
        return detailStepType == .cCompilation
        || detailStepType == .swiftCompilation
        || detailStepType == .compileStoryboard
        || detailStepType == .compileAssetsCatalog
        || detailStepType == .swiftAggregatedCompilation
    }
}

import Foundation

// swiftlint:disable file_length
public class IDEActivityLog: Encodable {
    public let version: Int8
    public let mainSection: IDEActivityLogSection

    public init(version: Int8, mainSection: IDEActivityLogSection) {
        self.version = version
        self.mainSection = mainSection
    }
}

public class IDEActivityLogSection: Encodable {
    public let sectionType: Int8
    public let domainType: String
    public let title: String
    public let signature: String
    public let timeStartedRecording: Double
    public var timeStoppedRecording: Double
    public var subSections: [IDEActivityLogSection]
    public let text: String
    public let messages: [IDEActivityLogMessage]
    public let wasCancelled: Bool
    public let isQuiet: Bool
    public var wasFetchedFromCache: Bool
    public let subtitle: String
    public let location: DVTDocumentLocation
    public let commandDetailDesc: String
    public let uniqueIdentifier: String
    public let localizedResultString: String
    public let xcbuildSignature: String
    public let attachments: [IDEActivityLogSectionAttachment]
    public let unknown: Int

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int) {
        self.sectionType = sectionType
        self.domainType = domainType
        self.title = title
        self.signature = signature
        self.timeStartedRecording = timeStartedRecording
        self.timeStoppedRecording = timeStoppedRecording
        self.subSections = subSections
        self.text = text
        self.messages = messages
        self.wasCancelled = wasCancelled
        self.isQuiet = isQuiet
        self.wasFetchedFromCache = wasFetchedFromCache
        self.subtitle = subtitle
        self.location = location
        self.commandDetailDesc = commandDetailDesc
        self.uniqueIdentifier = uniqueIdentifier
        self.localizedResultString = localizedResultString
        self.xcbuildSignature = xcbuildSignature
        self.attachments = attachments
        self.unknown = unknown
    }

}

public class IDEActivityLogUnitTestSection: IDEActivityLogSection {
    public let testsPassedString: String
    public let durationString: String
    public let summaryString: String
    public let suiteName: String
    public let testName: String
    public let performanceTestOutputString: String

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int,
                testsPassedString: String,
                durationString: String,
                summaryString: String,
                suiteName: String,
                testName: String,
                performanceTestOutputString: String
                ) {
        self.testsPassedString = testsPassedString
        self.durationString = durationString
        self.summaryString = summaryString
        self.suiteName = suiteName
        self.testName = testName
        self.performanceTestOutputString = performanceTestOutputString
        super.init(sectionType: sectionType,
                   domainType: domainType,
                   title: title,
                   signature: signature,
                   timeStartedRecording: timeStartedRecording,
                   timeStoppedRecording: timeStoppedRecording,
                   subSections: subSections,
                   text: text,
                   messages: messages,
                   wasCancelled: wasCancelled,
                   isQuiet: isQuiet,
                   wasFetchedFromCache: wasFetchedFromCache,
                   subtitle: subtitle,
                   location: location,
                   commandDetailDesc: commandDetailDesc,
                   uniqueIdentifier: uniqueIdentifier,
                   localizedResultString: localizedResultString,
                   xcbuildSignature: xcbuildSignature,
                   attachments: attachments,
                   unknown: unknown)
    }

    private enum CodingKeys: String, CodingKey {
        case testsPassedString
        case durationString
        case summaryString
        case suiteName
        case testName
        case performanceTestOutputString
    }

    /// Override the encode method to overcome a constraint where subclasses properties
    /// are not encoded by default
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(testsPassedString, forKey: .testsPassedString)
        try container.encode(durationString, forKey: .durationString)
        try container.encode(summaryString, forKey: .summaryString)
        try container.encode(suiteName, forKey: .suiteName)
        try container.encode(testName, forKey: .testName)
        try container.encode(performanceTestOutputString, forKey: .performanceTestOutputString)
    }

}

public class IDEActivityLogMessage: Encodable {
    public let title: String
    public let shortTitle: String
    public let timeEmitted: Double
    public let rangeEndInSectionText: UInt64
    public let rangeStartInSectionText: UInt64
    public let subMessages: [IDEActivityLogMessage]
    public let severity: Int
    public let type: String
    public let location: DVTDocumentLocation
    public let categoryIdent: String
    public let secondaryLocations: [DVTDocumentLocation]
    public let additionalDescription: String

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String) {
        self.title = title
        self.shortTitle = shortTitle
        self.timeEmitted = timeEmitted
        self.rangeEndInSectionText = rangeEndInSectionText
        self.rangeStartInSectionText = rangeStartInSectionText
        self.subMessages = subMessages
        self.severity = severity
        self.type = type
        self.location = location
        self.categoryIdent = categoryIdent
        self.secondaryLocations = secondaryLocations
        self.additionalDescription = additionalDescription
    }
}

public class IDEActivityLogAnalyzerResultMessage: IDEActivityLogMessage {

    public let resultType: String
    public let keyEventIndex: UInt64

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                resultType: String,
                keyEventIndex: UInt64) {

        self.resultType = resultType
        self.keyEventIndex = keyEventIndex

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case resultType
        case keyEventIndex
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(resultType, forKey: .resultType)
        try container.encode(keyEventIndex, forKey: .keyEventIndex)
    }
}

public class IDEActivityLogAnalyzerControlFlowStepMessage: IDEActivityLogMessage {

    public let parentIndex: UInt64
    public let endLocation: DVTDocumentLocation
    public let edges: [IDEActivityLogAnalyzerControlFlowStepEdge]

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                parentIndex: UInt64,
                endLocation: DVTDocumentLocation,
                edges: [IDEActivityLogAnalyzerControlFlowStepEdge]) {

        self.parentIndex = parentIndex
        self.endLocation = endLocation
        self.edges = edges

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case parentIndex
        case endLocation
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(parentIndex, forKey: .parentIndex)
        try container.encode(endLocation, forKey: .endLocation)
    }
}

public class DVTDocumentLocation: Encodable {
    public let documentURLString: String
    public let timestamp: Double

    public init(documentURLString: String, timestamp: Double) {
        self.documentURLString = documentURLString
        self.timestamp = timestamp
    }

}

public class DVTTextDocumentLocation: DVTDocumentLocation {
    public let startingLineNumber: UInt64
    public let startingColumnNumber: UInt64
    public let endingLineNumber: UInt64
    public let endingColumnNumber: UInt64
    public let characterRangeEnd: UInt64
    public let characterRangeStart: UInt64
    public let locationEncoding: UInt64

    public init(documentURLString: String,
                timestamp: Double,
                startingLineNumber: UInt64,
                startingColumnNumber: UInt64,
                endingLineNumber: UInt64,
                endingColumnNumber: UInt64,
                characterRangeEnd: UInt64,
                characterRangeStart: UInt64,
                locationEncoding: UInt64) {
        self.startingLineNumber = startingLineNumber
        self.startingColumnNumber = startingColumnNumber
        self.endingLineNumber = endingLineNumber
        self.endingColumnNumber = endingColumnNumber
        self.characterRangeEnd = characterRangeEnd
        self.characterRangeStart = characterRangeStart
        self.locationEncoding = locationEncoding
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    private enum CodingKeys: String, CodingKey {
        case startingLineNumber
        case startingColumnNumber
        case endingLineNumber
        case endingColumnNumber
        case characterRangeEnd
        case characterRangeStart
        case locationEncoding
    }

    /// Override the encode method to overcome a constraint where subclasses properties
    /// are not encoded by default
    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startingLineNumber, forKey: .startingLineNumber)
        try container.encode(startingColumnNumber, forKey: .startingColumnNumber)
        try container.encode(endingLineNumber, forKey: .endingLineNumber)
        try container.encode(endingColumnNumber, forKey: .endingColumnNumber)
        try container.encode(characterRangeEnd, forKey: .characterRangeEnd)
        try container.encode(characterRangeStart, forKey: .characterRangeStart)
        try container.encode(locationEncoding, forKey: .locationEncoding)
    }
}

public class IDEConsoleItem: Encodable {
    public let adaptorType: UInt64
    public let content: String
    public let kind: UInt64
    public let timestamp: Double

    public init(adaptorType: UInt64, content: String, kind: UInt64, timestamp: Double) {
        self.adaptorType = adaptorType
        self.content = content
        self.kind = kind
        self.timestamp = timestamp
    }
}

public class DBGConsoleLog: IDEActivityLogSection {
    public let logConsoleItems: [IDEConsoleItem]

    public init(sectionType: Int8,
                domainType: String,
                title: String,
                signature: String,
                timeStartedRecording: Double,
                timeStoppedRecording: Double,
                subSections: [IDEActivityLogSection],
                text: String,
                messages: [IDEActivityLogMessage],
                wasCancelled: Bool,
                isQuiet: Bool,
                wasFetchedFromCache: Bool,
                subtitle: String,
                location: DVTDocumentLocation,
                commandDetailDesc: String,
                uniqueIdentifier: String,
                localizedResultString: String,
                xcbuildSignature: String,
                attachments: [IDEActivityLogSectionAttachment],
                unknown: Int,
                logConsoleItems: [IDEConsoleItem]) {
        self.logConsoleItems = logConsoleItems
        super.init(sectionType: sectionType,
                   domainType: domainType,
                   title: title,
                   signature: signature,
                   timeStartedRecording: timeStartedRecording,
                   timeStoppedRecording: timeStoppedRecording,
                   subSections: subSections,
                   text: text,
                   messages: messages,
                   wasCancelled: wasCancelled,
                   isQuiet: isQuiet,
                   wasFetchedFromCache: wasFetchedFromCache,
                   subtitle: subtitle,
                   location: location,
                   commandDetailDesc: commandDetailDesc,
                   uniqueIdentifier: uniqueIdentifier,
                   localizedResultString: localizedResultString,
                   xcbuildSignature: xcbuildSignature,
                   attachments: attachments,
                   unknown: unknown)
    }

    private enum CodingKeys: String, CodingKey {
        case logConsoleItems
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(logConsoleItems, forKey: .logConsoleItems)
    }
}

public class IDEActivityLogAnalyzerControlFlowStepEdge: Encodable {
    public let startLocation: DVTDocumentLocation
    public let endLocation: DVTDocumentLocation

    public init(startLocation: DVTDocumentLocation, endLocation: DVTDocumentLocation) {
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
}

public class IDEActivityLogAnalyzerEventStepMessage: IDEActivityLogMessage {

    public let parentIndex: UInt64
    public let description: String
    public let callDepth: UInt64

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                parentIndex: UInt64,
                description: String,
                callDepth: UInt64) {

        self.parentIndex = parentIndex
        self.description = description
        self.callDepth = callDepth

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case parentIndex
        case description
        case callDepth
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(description, forKey: .description)
        try container.encode(parentIndex, forKey: .parentIndex)
        try container.encode(callDepth, forKey: .callDepth)
    }
}

public class IDEActivityLogActionMessage: IDEActivityLogMessage {

    public let action: String

    public init(title: String,
                shortTitle: String,
                timeEmitted: Double,
                rangeEndInSectionText: UInt64,
                rangeStartInSectionText: UInt64,
                subMessages: [IDEActivityLogMessage],
                severity: Int,
                type: String,
                location: DVTDocumentLocation,
                categoryIdent: String,
                secondaryLocations: [DVTDocumentLocation],
                additionalDescription: String,
                action: String) {

        self.action = action

        super.init(title: title,
                   shortTitle: shortTitle,
                   timeEmitted: timeEmitted,
                   rangeEndInSectionText: rangeEndInSectionText,
                   rangeStartInSectionText: rangeStartInSectionText,
                   subMessages: subMessages,
                   severity: severity,
                   type: type,
                   location: location,
                   categoryIdent: categoryIdent,
                   secondaryLocations: secondaryLocations,
                   additionalDescription: additionalDescription)
    }

    private enum CodingKeys: String, CodingKey {
        case action
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
    }
}

// MARK: IDEInterfaceBuilderKit

public class IBMemberID: Encodable {
    public let memberIdentifier: String

    public init(memberIdentifier: String) {
        self.memberIdentifier = memberIdentifier
    }
}

public class IBAttributeSearchLocation: Encodable {
    public let offsetFromStart: UInt64
    public let offsetFromEnd: UInt64
    public let keyPath: String

    public init(offsetFromStart: UInt64, offsetFromEnd: UInt64, keyPath: String) {
        self.offsetFromEnd = offsetFromEnd
        self.offsetFromStart = offsetFromStart
        self.keyPath = keyPath
    }
}

public class IBDocumentMemberLocation: DVTDocumentLocation {
    public let memberIdentifier: IBMemberID
    public let attributeSearchLocation: IBAttributeSearchLocation?

    public init(documentURLString: String,
                timestamp: Double,
                memberIdentifier: IBMemberID,
                attributeSearchLocation: IBAttributeSearchLocation?) {
        self.memberIdentifier = memberIdentifier
        self.attributeSearchLocation = attributeSearchLocation
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    private enum CodingKeys: String, CodingKey {
        case memberIdentifier
        case attributeSearchLocation
    }

    override public func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memberIdentifier, forKey: .memberIdentifier)
        try container.encode(attributeSearchLocation, forKey: .attributeSearchLocation)
    }
}

// MARK: Added in Xcode 14

////  From DVTFoundation.framework
public class DVTMemberDocumentLocation: DVTDocumentLocation, Equatable {

    public let member: String

    public init(documentURLString: String, timestamp: Double, member: String) {
        self.member = member
        super.init(documentURLString: documentURLString, timestamp: timestamp)
    }

    // MARK: Equatable method

    public static func == (lhs: DVTMemberDocumentLocation, rhs: DVTMemberDocumentLocation) -> Bool {
        return lhs.documentURLString == rhs.documentURLString &&
        lhs.timestamp == rhs.timestamp &&
        lhs.member == rhs.member
    }

}

// MARK: Added in Xcode 15.3

public class IDEActivityLogSectionAttachment: Encodable {
    public struct BuildOperationTaskMetrics: Codable {
        public let utime: UInt64
        public let stime: UInt64
        public let maxRSS: UInt64
        public let wcStartTime: UInt64
        public let wcDuration: UInt64
    }

    public let identifier: String
    public let majorVersion: UInt64
    public let minorVersion: UInt64
    public let metrics: BuildOperationTaskMetrics?

    public init(
        identifier: String,
        majorVersion: UInt64,
        minorVersion: UInt64,
        metrics: BuildOperationTaskMetrics?
    ) throws {
        self.identifier = identifier
        self.majorVersion = majorVersion
        self.minorVersion = minorVersion
        self.metrics = metrics
    }
}

import Foundation

extension NSRegularExpression {

    static func fromPattern(_ pattern: String) -> NSRegularExpression? {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            return nil
        }
    }
}


import Foundation

public class ClangCompilerParser {
    private static let timeTraceCompilerFlag = "-ftime-trace"
    private static let printStatisticsLinkerFlag = "-print_statistics"

    private lazy var timeTraceRegexp: NSRegularExpression? = {
        let pattern = "Time trace json-file dumped to (.*?)\\r"
        return NSRegularExpression.fromPattern(pattern)
    }()

    public func parseTimeTraceFile(_ logSection: IDEActivityLogSection) -> String? {
        guard let regex = timeTraceRegexp else {
            return nil
        }

        guard hasTimeTraceCompilerFlag(commandDesc: logSection.commandDetailDesc) else {
            return nil
        }

        let text = logSection.text
        let range = NSRange(location: 0, length: text.count)
        let matches = regex.matches(in: text, options: .reportProgress, range: range)
        guard let fileRange = matches.first?.range(at: 1) else {
            return nil
        }

        return text.substring(fileRange)
    }

    fileprivate func parseTimeAndPercentage(_ text: String, _ range: NSRange, _ pattern: String) -> (Double, Double) {
        var time = 0.0
        var percentage = 0.0

        if let regex = NSRegularExpression.fromPattern(pattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let timeRange = Range(match.range(at: 1), in: text) {
                    time = Double(text[timeRange]) ?? 0.0
                }

                if let percentageRange = Range(match.range(at: 2), in: text) {
                    percentage = Double(text[percentageRange]) ?? 0.0
                }
            }
        }

        return (time, percentage)
    }

    // swiftlint:disable large_tuple
    fileprivate func parsePagingInfo(_ text: String, _ range: NSRange) -> (Int, Int, Int) {
        var pageins = 0, pageouts = 0, faults = 0
        let pagingInfoPattern = "pageins=(\\d+), pageouts=(\\d+), faults=(\\d+)\r"
        if let regex = NSRegularExpression.fromPattern(pagingInfoPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let pageinsRange = Range(match.range(at: 1), in: text) {
                    pageins = Int(text[pageinsRange]) ?? 0
                }
                if let pageoutsRange = Range(match.range(at: 2), in: text) {
                    pageouts = Int(text[pageoutsRange]) ?? 0
                }
                if let faultsRange = Range(match.range(at: 3), in: text) {
                    faults = Int(text[faultsRange]) ?? 0
                }
            }
        }

        return (pageins, pageouts, faults)
    }

    // swiftlint:disable function_body_length
    public func parseLinkerStatistics(_ logSection: IDEActivityLogSection) -> LinkerStatistics? {
        guard hasPrintStatisticsLinkerFlag(commandDesc: logSection.commandDetailDesc) else {
            return nil
        }

        let text = logSection.text
        let range = NSRange(location: 0, length: text.count)
        let totalTimePattern = "ld total time:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let totalTime = parseTimeAndPercentage(text, range, totalTimePattern)

        let optionParsingPattern = "option parsing time:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let optionParsing = parseTimeAndPercentage(text, range, optionParsingPattern)

        let resolveSymbolPattern = "resolve symbols:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let resolveSymbol = parseTimeAndPercentage(text, range, resolveSymbolPattern)

        let buildAtomPattern = "build atom list:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let buildAtom = parseTimeAndPercentage(text, range, buildAtomPattern)

        let passesPattern = "passess:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let passes = parseTimeAndPercentage(text, range, passesPattern)

        let writeOutputPattern = "write output:\\s*(.*?) milliseconds \\(\\s*(.*?)%\\)\\r"
        let writeOutput = parseTimeAndPercentage(text, range, writeOutputPattern)

        let paging = parsePagingInfo(text, range)

        var objectFiles = 0, objectFilesBytes = 0
        var archiveFiles = 0, archiveFilesBytes = 0
        var dylibFiles = 0
        var totalFileBytes = 0

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en")
        numberFormatter.numberStyle = .decimal

        let fileInfoPattern = """
        processed\\s*(\\d+) object files,\\s*totaling\\s*(.*?) bytes\\r\
        processed\\s*(\\d+) archive files,\\s*totaling\\s*(.*?) bytes\\r\
        processed\\s*(\\d+) dylib files\\r\
        wrote output file\\s* totaling\\s*(.*) bytes\\r
        """
        if let regex = NSRegularExpression.fromPattern(fileInfoPattern) {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let objectFilesCountRange = Range(match.range(at: 1), in: text) {
                    objectFiles = Int(text[objectFilesCountRange]) ?? 0
                }
                if let objectFilesBytesRange = Range(match.range(at: 2), in: text) {
                    let number = numberFormatter.number(from: String(text[objectFilesBytesRange]))
                    objectFilesBytes = number?.intValue ?? 0
                }
                if let archiveFilesCountRange = Range(match.range(at: 3), in: text) {
                    archiveFiles = Int(text[archiveFilesCountRange]) ?? 0
                }
                if let archiveFilesBytesRange = Range(match.range(at: 4), in: text) {
                    let number = numberFormatter.number(from: String(text[archiveFilesBytesRange]))
                    archiveFilesBytes = number?.intValue ?? 0
                }
                if let dylibCountRange = Range(match.range(at: 5), in: text) {
                    dylibFiles = Int(text[dylibCountRange]) ?? 0
                }
                if let totalFilesBytesRange = Range(match.range(at: 6), in: text) {
                    let number = numberFormatter.number(from: String(text[totalFilesBytesRange]))
                    totalFileBytes = number?.intValue ?? 0
                }
            }
        }

        return LinkerStatistics(
            totalMS: totalTime.0,
            optionParsingMS: optionParsing.0,
            optionParsingPercent: optionParsing.1,
            objectFileProcessingMS: 0,
            objectFileProcessingPercent: 0,
            resolveSymbolsMS: resolveSymbol.0,
            resolveSymbolsPercent: resolveSymbol.1,
            buildAtomListMS: buildAtom.0,
            buildAtomListPercent: buildAtom.1,
            runPassesMS: passes.0,
            runPassesPercent: passes.1,
            writeOutputMS: writeOutput.0,
            writeOutputPercent: writeOutput.1,
            pageins: paging.0,
            pageouts: paging.1,
            faults: paging.2,
            objectFiles: objectFiles,
            objectFilesBytes: objectFilesBytes,
            archiveFiles: archiveFiles,
            archiveFilesBytes: archiveFilesBytes,
            dylibFiles: dylibFiles,
            wroteOutputFileBytes: totalFileBytes)
    }

    func hasTimeTraceCompilerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.timeTraceCompilerFlag) != nil
    }

    func hasPrintStatisticsLinkerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.printStatisticsLinkerFlag) != nil
    }
}

import Foundation

/// Reads the name of the machine where this command is executed
protocol MachineNameReader {
    var machineName: String? { get }
}

/// Implementation of `MachineReader` that uses the name of the host as the Machine name
class MacOSMachineNameReader: MachineNameReader {
    var machineName: String? {
        return Host.current().localizedName
    }
}

import Foundation

class BuildStatusSanitizer {
    static func sanitize(originalStatus: String) -> String {
        let sanitizedStatus = originalStatus
            .replacingOccurrences(of: "Build", with: "")
            .replacingOccurrences(of: "Clean", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitizedStatus
    }
}

import Foundation

extension IDEActivityLogSection {

    /// Returns the name of the target inside the `commandDetailDesc`
    /// - returns: The name of the target or nil if there is no target name in `commandDetailDesc`
    func getTargetFromCommand() -> String? {
        guard let startIndex = commandDetailDesc.range(of: "in target '"),
            let endIndex = commandDetailDesc.range(of: "' from project '") else {
                return nil
        }
        return String(commandDetailDesc[startIndex.upperBound..<endIndex.lowerBound])
    }

    /// Returns the Log with the subsections grouped in their Target
    ///
    /// Since Xcode 11, logs generated by xcodebuild have a flat structure, meaning that the steps
    /// are not grouped in Target sections. The only way to get the name of the target that a file belongs to
    /// is to parse the string `(in target 'ABC' from project Project)`.
    ///
    /// - returns An `IDEActivityLogSection` in which the subsections is an array of Targets and each one has
    /// an array of steps belonging to that target
    func groupedByTarget() -> IDEActivityLogSection {
        // The only way to know if the structure is flatten is to check the first elements
        // for the `(in target 'ABC' from project Project)` string
        let firstElements = subSections.prefix(15) // we only analyze up to the first 15 subsections
        let isFlatten = firstElements.contains { $0.getTargetFromCommand() != nil }
        if isFlatten {
            let mainTarget = "$MainTarget"
            let targetsDictionary = subSections.reduce(
                [String: IDEActivityLogSection]()) { targets, subSection -> [String: IDEActivityLogSection] in
                // some substeps belong to the root project, we use a fixed name for them
                let targetName = subSection.getTargetFromCommand() ?? mainTarget
                let target = getOrBuildTarget(targetName, in: targets, using: subSection)
                target.subSections.append(subSection)
                var updatedTargets = targets
                updatedTargets[targetName] = target
                return updatedTargets
            }
            let nonMainTargets = targetsDictionary.filter { (key: String, _) -> Bool in
                return key != mainTarget
            }
            var subSections = [IDEActivityLogSection]()
            if let mainTarget = targetsDictionary[mainTarget] {
                subSections.append(contentsOf: mainTarget.subSections)
            }
            subSections.append(contentsOf: nonMainTargets.values)
            let withTargets = self
            withTargets.subSections = subSections.sorted { lhs, rhs -> Bool in
                lhs.timeStartedRecording < rhs.timeStartedRecording
            }
            return withTargets
        } else {
            return self
        }
    }

    /// Parses the swift files compiled in a module when `whole module` is used
    ///
    /// - Parameter buildStep: the `BuildStep` that has the information about the module
    /// - Parameter parentCommandDetailDesc: The `CommandDetailDesc` of the parent of this LogSection.
    /// In some cases, the name of the individual Swift files are in this parent's property
    /// rather than in the current LogSection.
    /// - Parameter currentIndex: the Step current Index. This index is used to generated the unique identifier of
    /// the steps
    /// - Returns: An array of `BuildStep` with the data of each individual Swift file
    /// including the warnings and errors generated by its compilation.
    public func getSwiftIndividualSteps(buildStep: BuildStep,
                                        parentCommandDetailDesc: String,
                                        currentIndex: inout Int) -> [BuildStep]? {
        let pattern = #"^CompileSwift\s\w+\s\w+\s.+\.swift\s"#
        guard commandDetailDesc.range(of: pattern, options: .regularExpression) == nil else {
            return nil
        }
        let swiftFilePattern = #"\s([^\s]+\.swift)"#
        guard let regexp = NSRegularExpression.fromPattern(swiftFilePattern) else {
            return nil
        }
        var usedParentCommandDesc = false
        var matches = regexp.matches(in: commandDetailDesc,
                              options: .reportProgress,
                              range: NSRange(location: 0, length: commandDetailDesc.count))
        // If the list of compiled Swift Files are not in the commandDetailDesc, we check the parent's
        if matches.isEmpty {
            matches = regexp.matches(in: parentCommandDetailDesc,
                                     options: .reportProgress,
                                     range: NSRange(location: 0, length: parentCommandDetailDesc.count))
            usedParentCommandDesc = true
        }
        let desc = usedParentCommandDesc ? parentCommandDetailDesc : commandDetailDesc
        let swiftSteps = matches
            .filter { match in
                let file = desc.substring(match.range(at: 1))
                return !file.contains("com.apple.xcode.tools.swift")
            }
            .map { match -> BuildStep in
                let file = desc.substring(match.range(at: 1))
                currentIndex += 1
                return buildStep
                    .with(identifier: "\(buildStep.buildIdentifier)_\(currentIndex)")
                    .with(documentURL: "file://\(file)")
                    .with(title: "Compile \(file)")
                    .with(signature: "\(buildStep.signature) \(file)")
            }

        return assignNoticesFrom(buildStep, to: swiftSteps)
    }

    private func getOrBuildTarget(_ name: String,
                                  in targets: [String: IDEActivityLogSection],
                                  using section: IDEActivityLogSection)
        -> IDEActivityLogSection {
            if let target = targets[name] {
                target.timeStoppedRecording = section.timeStoppedRecording
                target.wasFetchedFromCache = target.wasFetchedFromCache && section.wasFetchedFromCache
                return target
            }
            return buildTargetSection(name, with: section)
    }

    private func buildTargetSection(_ name: String, with section: IDEActivityLogSection) -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: 2,
                                     domainType: section.domainType,
                                     title: "Build target \(name)",
            signature: name,
            timeStartedRecording: section.timeStartedRecording,
            timeStoppedRecording: section.timeStoppedRecording,
            subSections: [IDEActivityLogSection](),
            text: "",
            messages: [IDEActivityLogMessage](),
            wasCancelled: section.wasCancelled,
            isQuiet: section.isQuiet,
            wasFetchedFromCache: section.wasFetchedFromCache,
            subtitle: "",
            location: DVTDocumentLocation(documentURLString: "", timestamp: 0.0),
            commandDetailDesc: "",
            uniqueIdentifier: "",
            localizedResultString: "",
            xcbuildSignature: "",
            attachments: section.attachments,
            unknown: 0)
    }

    private func assignNoticesFrom(_ buildStep: BuildStep, to swiftSteps: [BuildStep]) -> [BuildStep] {
        var assignedNotes: Set<Notice> = Set()
        var assignedWarnings: Set<Notice> = Set()
        var assignedErrors: Set<Notice> = Set()
        var updatedSteps = swiftSteps.map { swiftStep -> BuildStep in
            let stepNotes = buildStep.notes?.filter { $0.documentURL == swiftStep.documentURL }
            assignedNotes.formUnion(stepNotes ?? [])
            let stepWarnings = buildStep.warnings?.filter { $0.documentURL == swiftStep.documentURL }
            assignedWarnings.formUnion(stepWarnings ?? [])
            let stepErrors = buildStep.errors?.filter { $0.documentURL == swiftStep.documentURL }
            assignedErrors.formUnion(stepErrors ?? [])
            return swiftStep.with(errors: stepErrors, notes: stepNotes, warnings: stepWarnings)
        }

        // Some notices can't be assigned to a step's documentURL, we just put them in the first
        let remainingErrors = Set(buildStep.errors ?? []).subtracting(assignedErrors)
        let remainingNotes = Set(buildStep.notes ?? []).subtracting(assignedNotes)
        let remainingWarnings = Set(buildStep.warnings ?? []).subtracting(assignedWarnings)
        if !updatedSteps.isEmpty {
            let first = updatedSteps.remove(at: 0)
            let errors = Array(remainingErrors.union(Set(first.errors ?? [])))
            let notes = Array(remainingNotes.union(Set(first.notes ?? [])))
            let warnings = Array(remainingWarnings.union(Set(first.warnings ?? [])))
            updatedSteps.insert(first.with(errors: errors,
                                           notes: notes,
                                           warnings: warnings), at: 0)
        }
        return updatedSteps
    }

}

import Foundation

extension Array where Element: Hashable {

    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

}

extension Array where Element: Notice {

    func getWarnings() -> [Notice] {
        return filter {
            $0.type == .swiftWarning ||
            $0.type == .clangWarning ||
            $0.type == .projectWarning ||
            $0.type == .analyzerWarning ||
            $0.type == .interfaceBuilderWarning ||
            $0.type == .deprecatedWarning
        }
    }

    func getErrors() -> [Notice] {
        return filter {
            $0.type == .swiftError ||
            $0.type == .error ||
            $0.type == .clangError ||
            $0.type == .linkerError ||
            $0.type == .packageLoadingError ||
            $0.type == .scriptPhaseError ||
            $0.type == .failedCommandError
        }
    }

    func getNotes() -> [Notice] {
        return filter {
            $0.type == .note
        }
    }
}


import Foundation

/// Parses the .xcactivitylog into a tree of `BuildStep`
// swiftlint:disable type_body_length
public final class ParserBuildSteps {

    let machineName: String
    var buildIdentifier = ""
    var buildStatus = ""
    var currentIndex = 0
    var totalErrors = 0
    var totalWarnings = 0
    var targetErrors = 0
    var targetWarnings = 0
    let swiftCompilerParser = SwiftCompilerParser()
    let clangCompilerParser = ClangCompilerParser()

    /// If true, the details of Warnings won't be added.
    /// Useful to save space.
    let omitWarningsDetails: Bool

    /// If true, the Notes won't be parsed.
    /// Usefult to save space.
    let omitNotesDetails: Bool

    /// If true, tasks with more than a 100 issues will be
    /// truncated to have only 100
    let truncLargeIssues: Bool

    public lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        return formatter
    }()

    lazy var warningCountRegexp: NSRegularExpression? = {
        let pattern = "([0-9]) warning[s]? generated"
        return NSRegularExpression.fromPattern(pattern)
    }()

    lazy var schemeRegexp: NSRegularExpression? = {
        let pattern = "scheme (.*)"
        return NSRegularExpression.fromPattern(pattern)
    }()

    lazy var targetRegexp: NSRegularExpression? = {
        let pattern = "BUILD( AGGREGATE)? TARGET (.*?) OF PROJECT"
        return NSRegularExpression.fromPattern(pattern)
    }()

    lazy var clangArchRegexp: NSRegularExpression? = {
        let pattern = "normal (\\w+) objective-c"
        return NSRegularExpression.fromPattern(pattern)
    }()

    lazy var swiftcArchRegexp: NSRegularExpression? = {
        let pattern = "^CompileSwift normal (\\w*) "
        return NSRegularExpression.fromPattern(pattern)
    }()

    /// - parameter machineName: The name of the machine. It will be used to create a unique identifier
    /// for the log. If `nil`, the host name will be used instead.
    /// - parameter omitWarningsDetails: if true, the Warnings won't be parsed
    /// - parameter omitNotesDetails: if true, the Notes won't be parsed
    /// - parameter truncLargeIssues: if true, tasks with more than a 100 issues will be truncated to have a 100
    public init(machineName: String? = nil,
                omitWarningsDetails: Bool,
                omitNotesDetails: Bool,
                truncLargeIssues: Bool) {
        if let machineName = machineName {
            self.machineName = machineName
        } else {
            self.machineName = MacOSMachineNameReader().machineName ?? "unknown"
        }
        self.omitWarningsDetails = omitWarningsDetails
        self.omitNotesDetails = omitNotesDetails
        self.truncLargeIssues = truncLargeIssues
    }

    /// Parses the content from an Xcode log into a `BuildStep`
    /// - parameter activityLog: An `IDEActivityLog`
    /// - returns: A `BuildStep` with the parsed content from the log.
    public func parse(activityLog: IDEActivityLog) throws -> BuildStep {
        self.buildIdentifier = "\(machineName)_\(activityLog.mainSection.uniqueIdentifier)"
        buildStatus = BuildStatusSanitizer.sanitize(originalStatus: activityLog.mainSection.localizedResultString)
        let mainSectionWithTargets = activityLog.mainSection.groupedByTarget()
        var mainBuildStep = try parseLogSection(logSection: mainSectionWithTargets, type: .main, parentSection: nil)
        mainBuildStep.errorCount = totalErrors
        mainBuildStep.warningCount = totalWarnings
        mainBuildStep = decorateWithSwiftcTimes(mainBuildStep)
        return mainBuildStep
    }

    // swiftlint:disable function_body_length cyclomatic_complexity
    public func parseLogSection(logSection: IDEActivityLogSection,
                                type: BuildStepType,
                                parentSection: BuildStep?,
                                parentLogSection: IDEActivityLogSection? = nil)
        throws -> BuildStep {
            currentIndex += 1
            let detailType = type == .detail ? DetailStepType.getDetailType(signature: logSection.signature) : .none
            var schema = "", parentIdentifier = ""
            if type == .main {
                schema = getSchema(title: logSection.title)
            } else if let parentSection = parentSection {
                schema = parentSection.schema
                parentIdentifier = parentSection.identifier
            }
            if type == .target {
                targetErrors = 0
                targetWarnings = 0
            }
            let notices = parseWarningsAndErrorsFromLogSection(logSection, forType: detailType)
            let warnings: [Notice]? = notices?["warnings"]
            let errors: [Notice]? = notices?["errors"]
            let notes: [Notice]? = notices?["notes"]
            var errorCount: Int = 0, warningCount: Int = 0
            if let errors = errors {
                errorCount = errors.count
                totalErrors += errors.count
                targetErrors += errors.count
            }
            if let warnings = warnings {
                warningCount = warnings.count
                totalWarnings += warnings.count
                targetWarnings += warnings.count
            }
            var step = BuildStep(type: type,
                                 machineName: machineName,
                                 buildIdentifier: self.buildIdentifier,
                                 identifier: "\(self.buildIdentifier)_\(currentIndex)",
                                 parentIdentifier: parentIdentifier,
                                 domain: logSection.domainType,
                                 title: type == .target ? getTargetName(logSection.title) : logSection.title,
                                 signature: logSection.signature,
                                 startDate: toDate(timeInterval: logSection.timeStartedRecording),
                                 endDate: toDate(timeInterval: logSection.timeStoppedRecording),
                                 startTimestamp: toTimestampSince1970(timeInterval: logSection.timeStartedRecording),
                                 endTimestamp: toTimestampSince1970(timeInterval: logSection.timeStoppedRecording),
                                 duration: getDuration(startTimeInterval: logSection.timeStartedRecording,
                                                       endTimeInterval: logSection.timeStoppedRecording),
                                 detailStepType: detailType,
                                 buildStatus: buildStatus,
                                 schema: schema,
                                 subSteps: [BuildStep](),
                                 warningCount: warningCount,
                                 errorCount: errorCount,
                                 architecture: parseArchitectureFromLogSection(logSection, andType: detailType),
                                 documentURL: logSection.location.documentURLString,
                                 warnings: omitWarningsDetails ? [] : warnings,
                                 errors: errors,
                                 notes: omitNotesDetails ? [] : notes,
                                 swiftFunctionTimes: nil,
                                 fetchedFromCache: wasFetchedFromCache(parent:
                                    parentSection, section: logSection),
                                 compilationEndTimestamp: 0,
                                 compilationDuration: 0,
                                 clangTimeTraceFile: nil,
                                 linkerStatistics: nil,
                                 swiftTypeCheckTimes: nil
                                 )

            step.subSteps = try logSection.subSections.map { subSection -> BuildStep in
                let subType: BuildStepType = type == .main ? .target : .detail
                return try parseLogSection(logSection: subSection,
                                           type: subType,
                                           parentSection: step,
                                           parentLogSection: logSection)
            }
            if type == .target {
                step.warningCount = targetWarnings
                step.errorCount = targetErrors
            } else if type == .detail {
                step = step.moveSwiftStepsToRoot()
            }
            if step.detailStepType == .swiftCompilation {
                if step.fetchedFromCache == false {
                    swiftCompilerParser.addLogSection(logSection)
                }
                if let swiftSteps = logSection.getSwiftIndividualSteps(buildStep: step,
                                                                       parentCommandDetailDesc:
                                                                       parentLogSection?.commandDetailDesc ?? "",
                                                                       currentIndex: &currentIndex) {
                    step.subSteps.append(contentsOf: swiftSteps)
                    step = step.withFilteredNotices()
                }
            }

            if step.fetchedFromCache == false && step.detailStepType == .cCompilation {
                step.clangTimeTraceFile = "file://\(clangCompilerParser.parseTimeTraceFile(logSection) ?? "")"
            }

            if step.fetchedFromCache == false && step.detailStepType == .linker {
                step.linkerStatistics = clangCompilerParser.parseLinkerStatistics(logSection)
            }

            step = addCompilationTimes(step: step)
            return step
    }

    private func toDate(timeInterval: Double) -> String {
        return dateFormatter.string(from: Date(timeIntervalSinceReferenceDate: timeInterval))
    }

    private func toTimestampSince1970(timeInterval: Double) -> Double {
        return Date(timeIntervalSinceReferenceDate: timeInterval).timeIntervalSince1970
    }

    private func getDuration(startTimeInterval: Double, endTimeInterval: Double) -> Double {
        var duration = endTimeInterval - startTimeInterval
        // If the endtime is almost the same as the endtime, we got a constant
        // in the tokens and a date in the future (year 4001). Here we normalize it to 0.0 secs
        if endTimeInterval >= 63113904000.0 {
            duration = 0.0
        }
        duration = duration >= 0 ? duration : 0.0
        return duration
    }

    private func getSchema(title: String) -> String {
        let schema = title.replacingOccurrences(of: "Build ", with: "")
        guard let schemaRegexp = schemeRegexp else {
            return schema
        }
        let range = NSRange(location: 0, length: title.count)
        let matches = schemaRegexp.matches(in: title, options: .reportCompletion, range: range)
        guard let match = matches.first else {
            return schema
        }
        return title.substring(match.range(at: 1))
    }

    private func toBuildStep(domainType: Int8) -> BuildStepType {
        switch domainType {
        case 0:
            return .main
        case 1:
            return .target
        case 2:
            return .detail
        default:
            return .detail
        }
    }

    /// In CLI logs, the target name is enclosed in a string like
    /// === BUILD TARGET TargetName OF PROJECT ProjectName WITH CONFIGURATION config ===
    /// This function extracts the target name of it.
    private func getTargetName(_ text: String) -> String {
        guard let targetRegexp = targetRegexp else {
            return text
        }
        let range = NSRange(location: 0, length: text.count)
        let matches = targetRegexp.matches(in: text, options: .reportCompletion, range: range)
        guard let match = matches.first, match.numberOfRanges == 3 else {
            return text
        }
        return "Target \(text.substring(match.range(at: 2)))"
    }

    private func parseArchitectureFromLogSection(_ logSection: IDEActivityLogSection,
                                                 andType type: DetailStepType) -> String {
        guard let clangArchRegexp = clangArchRegexp, let swiftcArchRegexp = swiftcArchRegexp else {
            return ""
        }
        switch type {
        case .cCompilation:
            return parseArchitectureFromCommand(command: logSection.signature, regexp: clangArchRegexp)
        case .swiftCompilation:
            return parseArchitectureFromCommand(command: logSection.signature, regexp: swiftcArchRegexp)
        default:
            return ""
        }
    }

    private func parseArchitectureFromCommand(command: String, regexp: NSRegularExpression) -> String {
        let range = NSRange(location: 0, length: command.count)
        let matches = regexp.matches(in: command, options: .reportCompletion, range: range)
        guard let match = matches.first else {
            return ""
        }
        return command.substring(match.range(at: 1))
    }

    private func parseWarningsAndErrorsFromLogSection(_ logSection: IDEActivityLogSection, forType type: DetailStepType)
        -> [String: [Notice]]? {
        let notices = Notice.parseFromLogSection(logSection, forType: type, truncLargeIssues: truncLargeIssues)
        return ["warnings": notices.getWarnings(),
                "errors": notices.getErrors(),
                "notes": notices.getNotes()]
    }

    private func decorateWithSwiftcTimes(_ mainStep: BuildStep) -> BuildStep {
        swiftCompilerParser.parse()
        guard swiftCompilerParser.hasFunctionTimes() || swiftCompilerParser.hasTypeChecks() else {
            return mainStep
        }
        var mutableMainStep = mainStep
        mutableMainStep.subSteps = mainStep.subSteps.map { subStep -> BuildStep in
            var mutableTargetStep = subStep
            mutableTargetStep.subSteps = addSwiftcTimesSteps(mutableTargetStep.subSteps)
            return mutableTargetStep
        }
        return mutableMainStep
    }

    private func addSwiftcTimesSteps(_ subSteps: [BuildStep]) -> [BuildStep] {
        return subSteps.map { subStep -> BuildStep in
            switch subStep.detailStepType {
            case .swiftCompilation:
                var mutableSubStep = subStep
                if swiftCompilerParser.hasFunctionTimes() {
                    mutableSubStep.swiftFunctionTimes = swiftCompilerParser.findFunctionTimesForFilePath(
                    subStep.documentURL)
                }
                if swiftCompilerParser.hasTypeChecks() {
                    mutableSubStep.swiftTypeCheckTimes =
                        swiftCompilerParser.findTypeChecksForFilePath(subStep.documentURL)
                }
                if mutableSubStep.subSteps.count > 0 {
                     mutableSubStep.subSteps = addSwiftcTimesSteps(subStep.subSteps)
                }
                return mutableSubStep
            case .swiftAggregatedCompilation:
                var mutableSubStep = subStep
                mutableSubStep.subSteps = addSwiftcTimesSteps(subStep.subSteps)
                return mutableSubStep
            default:
                return subStep
            }
        }
    }

    private func wasFetchedFromCache(parent: BuildStep?, section: IDEActivityLogSection) -> Bool {
        if section.wasFetchedFromCache {
            return section.wasFetchedFromCache
        }
        return parent?.fetchedFromCache ?? false
    }

    func addCompilationTimes(step: BuildStep) -> BuildStep {
        switch step.type {
        case .detail:
            return step.with(newCompilationEndTimestamp: step.endTimestamp,
                             andCompilationDuration: step.duration)
        case .target:
            return addCompilationTimesToTarget(step)
        case .main:
            return addCompilationTimesToApp(step)
        }
    }

    private func addCompilationTimesToTarget(_ target: BuildStep) -> BuildStep {

        let lastCompilationStep = target.subSteps
            .filter { $0.isCompilationStep() && $0.fetchedFromCache == false }
            .max { $0.compilationEndTimestamp < $1.compilationEndTimestamp }
        guard let lastStep = lastCompilationStep else {
            return target.with(newCompilationEndTimestamp: target.startTimestamp, andCompilationDuration: 0.0)
        }
        return target.with(newCompilationEndTimestamp: lastStep.compilationEndTimestamp,
                         andCompilationDuration: lastStep.compilationEndTimestamp - target.startTimestamp)
    }

    private func addCompilationTimesToApp(_ app: BuildStep) -> BuildStep {
        let lastCompilationStep = app.subSteps
            .filter { $0.compilationDuration > 0 && $0.fetchedFromCache == false }
            .max { $0.compilationEndTimestamp < $1.compilationEndTimestamp }
        guard let lastStep = lastCompilationStep else {
            return app.with(newCompilationEndTimestamp: app.startTimestamp,
                            andCompilationDuration: 0.0)
        }
        return app.with(newCompilationEndTimestamp: lastStep.compilationEndTimestamp,
                         andCompilationDuration: lastStep.compilationEndTimestamp - app.startTimestamp)
    }

}

import Foundation

/// Parses Swift Function times generated by `swiftc`
/// if you pass the flags `-Xfrontend -debug-time-expression-type-checking`
class SwiftCompilerTypeCheckOptionParser: SwiftCompilerTimeOptionParser {

    private static let compilerFlag = "-debug-time-expression-type-checking"

    func hasCompilerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.compilerFlag) != nil
    }

    func parse(from commands: [String: Int]) -> [String: [SwiftTypeCheck]] {
        return commands.compactMap { parse(command: $0.key, occurrences: $0.value) }
            .joined().reduce([:]) { (typeChecksPerFile, typeCheckTime)
        -> [String: [SwiftTypeCheck]] in
            var typeChecksPerFile = typeChecksPerFile
            if var typeChecks = typeChecksPerFile[typeCheckTime.file] {
                typeChecks.append(typeCheckTime)
                typeChecksPerFile[typeCheckTime.file] = typeChecks
            } else {
                typeChecksPerFile[typeCheckTime.file] = [typeCheckTime]
            }
            return typeChecksPerFile
        }
    }

    private func parse(command: String, occurrences: Int) -> [SwiftTypeCheck]? {
        return command.components(separatedBy: "\r").compactMap { commandLine in
            // 0.14ms   /users/mnf/project/SomeFile.swift:10:12
            let parts = commandLine.components(separatedBy: "\t")

            guard parts.count == 2 else {
                return nil
            }

            // 0.14ms
            let duration = parseCompileDuration(parts[0])

            // /users/mnf/project/SomeFile.swift:10:12
            let fileAndLocation = parts[1]
            guard let (file, line, column) = parseNameAndLocation(from: fileAndLocation) else {
                return nil
            }

            return SwiftTypeCheck(file: file,
                                  durationMS: duration,
                                  startingLine: line,
                                  startingColumn: column,
                                  occurrences: occurrences)
        }
    }

}


import Foundation

/// Parses `swiftc` compiler times generated by
/// `-Xfrontend` flags such as `-debug-time-function-bodies` and `-debug-time-expression-type-checking`
public class SwiftCompilerParser {

    /// Array to store the text of the log sections and their commandDetailDesc
    var commands = [(String, String)]()

    /// Dictionary to store the function times found per filepath
    var functionsPerFile: [String: [SwiftFunctionTime]]?

    /// Dictionary to store the type checker times found per filepath
    var typeChecksPerFile: [String: [SwiftTypeCheck]]?

    let functionTimes = SwiftCompilerFunctionTimeOptionParser()

    let typeCheckTimes = SwiftCompilerTypeCheckOptionParser()

    public func addLogSection(_ logSection: IDEActivityLogSection) {
        commands.append((logSection.text, logSection.commandDetailDesc))
    }

    /// Checks the `commandDetailDesc` stored by the function `addLogSection`
    /// to know if the command `text` contains data about the swift function times.
    /// If there is data, the `text` wit that raw data is returned as part of a Set.
    ///
    /// - Returns: a Dictionary of Strings with the raw Swift compiler times data as key and
    /// the number of ocurrences as value
    public func findRawSwiftTimes() -> [String: Int] {
        let insertQueue = DispatchQueue(label: "swift_function_times_queue")
        var textsAndOccurrences: [String: Int] = [:]
        DispatchQueue.concurrentPerform(iterations: commands.count) { index in
            let (rawFunctionTimes, commandDesc) = commands[index]

            let hasCompilerFlag = functionTimes.hasCompilerFlag(commandDesc: commandDesc)
                                  || typeCheckTimes.hasCompilerFlag(commandDesc: commandDesc)

            guard hasCompilerFlag && rawFunctionTimes.isEmpty == false else {
                return
            }
            insertQueue.sync {
                let outputOccurrence = (textsAndOccurrences[rawFunctionTimes] ?? 0) + 1
                textsAndOccurrences[rawFunctionTimes] = outputOccurrence
            }
        }
        return textsAndOccurrences
    }

    /// Parses the swift function times and store them internally
    public func parse() {
        let rawTexts = findRawSwiftTimes()
        functionsPerFile = functionTimes.parse(from: rawTexts)
        typeChecksPerFile = typeCheckTimes.parse(from: rawTexts)
    }

    public func findFunctionTimesForFilePath(_ filePath: String) -> [SwiftFunctionTime]? {
        // File paths found in IDEActivityLogSection.text are unescaped
        // so percent encoding needs to be removed from filePath
        guard let unescapedFilePath = filePath.removingPercentEncoding else {
            return nil
        }
        return functionsPerFile?[unescapedFilePath]
    }

    public func findTypeChecksForFilePath(_ filePath: String) -> [SwiftTypeCheck]? {
        // File paths found in IDEActivityLogSection.text are unescaped
         // so percent encoding needs to be removed from filePath
        guard let unescapedFilePath = filePath.removingPercentEncoding else {
            return nil
        }
        return typeChecksPerFile?[unescapedFilePath]
    }

    public func hasFunctionTimes() -> Bool {
        guard let functionsPerFile = functionsPerFile else {
            return false
        }
        return functionsPerFile.isEmpty == false
    }

    public func hasTypeChecks() -> Bool {
        guard let typeChecksPerFile = typeChecksPerFile else {
            return false
        }
        return typeChecksPerFile.isEmpty == false
    }

}

import Foundation

/// Parses `swiftc` commands for time compiler outputs
protocol SwiftCompilerTimeOptionParser {

    associatedtype SwiftcOption

    /// Returns true if the compiler command included the flag to generate
    /// this compiler report
    /// - Parameter commandDesc: The command description
    func hasCompilerFlag(commandDesc: String) -> Bool

    /// Parses the Set of commands to look for swift compiler time outputs of type `SwiftcOption`
    /// - Parameter commands: Dictionary of command descriptions and ocurrences
    /// - Returns: A dictionary using the key as file and the Compiler time output as value
    func parse(from commands: [String: Int]) -> [String: [SwiftcOption]]

}

extension SwiftCompilerTimeOptionParser {

    /// Parses /users/mnf/project/SomeFile.swift:10:12
    /// - Returns: ("file:///users/mnf/project/SomeFile.swift", 10, 12)
    // swiftlint:disable:next large_tuple
    func parseNameAndLocation(from fileAndLocation: String) -> (String, Int, Int)? {
        // /users/mnf/project/SomeFile.swift:10:12
        let fileAndLocationParts = fileAndLocation.components(separatedBy: ":")
        let rawFile = fileAndLocationParts[0]

        guard rawFile != "<invalid loc>" else {
            return nil
        }

        guard
            fileAndLocationParts.count == 3,
            let line = Int(fileAndLocationParts[1]),
            let column = Int(fileAndLocationParts[2])
        else {
            return nil
        }

        let file = prefixWithFileURL(fileName: rawFile)

        return (file, line, column)
    }

    /// Parses
    func parseCompileDuration(_ durationString: String) -> Double {
        if let duration = Double(durationString.replacingOccurrences(of: "ms", with: "")) {
            return duration
        }
        return 0.0
    }

    /// Transforms the fileName to a file URL to match the one in IDELogSection.documentURL
    /// It doesn't use `URL` class to do it, because it was slow in benchmarks
    /// - Parameter fileName: String with a fileName
    /// - Returns: A String with the URL to the file like `file:///`
    func prefixWithFileURL(fileName: String) -> String {
        return "file://\(fileName)"
    }
}


import Foundation

/// Parses Swift Function times generated by `swiftc`
/// if you pass the flags `-Xfrontend -debug-time-function-bodies`
class SwiftCompilerFunctionTimeOptionParser: SwiftCompilerTimeOptionParser {

    private static let compilerFlag = "-debug-time-function-bodies"

    func hasCompilerFlag(commandDesc: String) -> Bool {
        commandDesc.range(of: Self.compilerFlag) != nil
    }

    func parse(from commands: [String: Int]) -> [String: [SwiftFunctionTime]] {
        let functionsPerFile = commands.compactMap { parse(command: $0.key, occurrences: $0.value) }
            .joined().reduce([:]) { (functionsPerFile, functionTime)
        -> [String: [SwiftFunctionTime]] in
            var functionsPerFile = functionsPerFile
            if var functions = functionsPerFile[functionTime.file] {
                functions.append(functionTime)
                functionsPerFile[functionTime.file] = functions
            } else {
                functionsPerFile[functionTime.file] = [functionTime]
            }
            return functionsPerFile
        }
        return functionsPerFile
    }

    private func parse(command: String, occurrences: Int) -> [SwiftFunctionTime]? {
        let functions: [SwiftFunctionTime] = command.components(separatedBy: "\r").compactMap { commandLine in

            // 0.14ms   /users/mnf/project/SomeFile.swift:10:12   someMethod(param:)
            let parts = commandLine.components(separatedBy: "\t")

            guard parts.count == 3 else {
                return nil
            }

            // 0.14ms
            let duration = parseCompileDuration(parts[0])

            // /users/mnf/project/SomeFile.swift:10:12
            let fileAndLocation = parts[1]
            guard let (file, line, column) = parseNameAndLocation(from: fileAndLocation) else {
                return nil
            }

            // someMethod(param:)
            let signature = parts[2]

            return SwiftFunctionTime(file: file,
                                     durationMS: duration,
                                     startingLine: line,
                                     startingColumn: column,
                                     signature: signature,
                                     occurrences: occurrences)
        }

        return functions
    }
}


import Foundation

/// Represents the time it took to the Swift Compiler to type check an expression
public struct SwiftTypeCheck: Encodable, Equatable {

    /// URL of the file where the function is
    public let file: String

    /// Duration in Miliseconds
    public let durationMS: Double

    /// Line number where the function is declared
    public let startingLine: Int

    /// Column number where the function is declared
    public let startingColumn: Int

    /// Number of occurences this type is checked during the build
    public let occurrences: Int

}


import Foundation

public struct Prefix {

    let prefix: String

    public init(_ prefix: String) {
        self.prefix = prefix.lowercased()
    }

    private func match(_ input: String) -> Bool {
        return input.lowercased().starts(with: prefix)
    }
}

extension Prefix {
    static func ~= (prefix: Prefix, input: String) -> Bool {
        return prefix.match(input)
    }
}

import Foundation

/// The type of a Notice
public enum NoticeType: String, Codable {

    /// Notes
    case note

    /// A warning thrown by the Swift compiler
    case swiftWarning

    /// A warning thrown by the C compiler
    case clangWarning

    /// A warning at a project level. For instance:
    /// "Warning Swift 3 mode has been deprecated and will be removed in a later version of Xcode"
    case projectWarning

    /// An error in a non-compilation step. For instance creating a directory or running a shell script phase
    case error

    /// An error thrown by the Swift compiler
    case swiftError

    /// An error thrown by the C compiler
    case clangError

    /// A warning returned by Xcode static analyzer
    case analyzerWarning

    /// A warning inside an Interface Builder file
    case interfaceBuilderWarning

    /// A warning about the usage of a deprecated API
    case deprecatedWarning

    /// Error thrown by the Linker
    case linkerError

    /// Error loading Swift Packages
    case packageLoadingError

    /// Error running a Build Phase's script
    case scriptPhaseError

    /// Failed command error (e.g. ValidateEmbeddedBinary, CodeSign)
    case failedCommandError

    // swiftlint:disable:next cyclomatic_complexity
    public static func fromTitle(_ title: String) -> NoticeType? {
        switch title {
        case "Swift Compiler Warning":
            return .swiftWarning
        case "Notice":
            return .note
        case "Swift Compiler Error":
            return .swiftError
        case Prefix("Lexical"), Suffix("Semantic Issue"), "Parse Issue", "Uncategorized":
            return .clangError
        case Suffix("Deprecations"):
            return .deprecatedWarning
        case "Warning", "Apple Mach-O Linker Warning", "Target Integrity":
            return .projectWarning
        case Suffix("Error"):
            return .error
        case Suffix("Notice"):
            return .note
        case Prefix("/* com.apple.ibtool.document.warnings */"):
            return .interfaceBuilderWarning
        case "Package Loading":
            return .packageLoadingError
        case Contains("Command PhaseScriptExecution"):
            return .scriptPhaseError
        case Prefix("error: Swiftc"):
            return .swiftError
        case Suffix("failed with a nonzero exit code"):
            return .failedCommandError
        default:
            return .note
        }
    }
}

import Foundation

public struct Contains {

    let str: String

    public init(_ str: String) {
        self.str = str.lowercased()
    }

    private func match(_ input: String) -> Bool {
        return input.lowercased().contains(str)
    }
}

extension Contains {
    static func ~= (contains: Contains, input: String) -> Bool {
        return contains.match(input)
    }
}


import Foundation

public struct Suffix {

    let suffix: String

    public init(_ suffix: String) {
        self.suffix = suffix.lowercased()
    }

    private func match(_ input: String) -> Bool {
        return input.lowercased().hasSuffix(suffix)
    }
}

extension Suffix {
    static func ~= (suffix: Suffix, input: String) -> Bool {
        return suffix.match(input)
    }
}


import Foundation

/// Xcode reports warnings, errors and notes as IDEActivityLogMessage. This class
/// wraps that data
public class Notice: Codable, Equatable {

    public let type: NoticeType
    public let title: String
    public let clangFlag: String?
    public let documentURL: String
    public let severity: Int
    public let startingLineNumber: UInt64
    public let endingLineNumber: UInt64
    public let startingColumnNumber: UInt64
    public let endingColumnNumber: UInt64
    public let characterRangeEnd: UInt64
    public let characterRangeStart: UInt64
    public let interfaceBuilderIdentifier: String?
    public let detail: String?

    static var clangWarningRegexp: NSRegularExpression? = {
        let pattern = "\\[(-W[\\w-,]*)\\]+"
        return NSRegularExpression.fromPattern(pattern)
    }()

    /// Public initializer
    public init(type: NoticeType,
                title: String,
                clangFlag: String?,
                documentURL: String,
                severity: Int,
                startingLineNumber: UInt64,
                endingLineNumber: UInt64,
                startingColumnNumber: UInt64,
                endingColumnNumber: UInt64,
                characterRangeEnd: UInt64,
                characterRangeStart: UInt64,
                interfaceBuilderIdentifier: String? = nil,
                detail: String? = nil) {
        self.type = type
        self.title = title
        self.clangFlag = clangFlag
        self.documentURL = documentURL
        self.severity = severity
        self.startingLineNumber = startingLineNumber
        self.endingLineNumber = endingLineNumber
        self.startingColumnNumber = startingColumnNumber
        self.endingColumnNumber = endingColumnNumber
        self.characterRangeEnd = characterRangeEnd
        self.characterRangeStart = characterRangeStart
        self.interfaceBuilderIdentifier = interfaceBuilderIdentifier
        self.detail = detail
    }

    public init?(withType type: NoticeType?,
                 logMessage: IDEActivityLogMessage,
                 clangFlag: String? = nil,
                 detail: String? = nil) {
        guard let type = type else {
            return nil
        }
        if let location = logMessage.location as? IBDocumentMemberLocation {
            self.interfaceBuilderIdentifier = location.memberIdentifier.memberIdentifier
        } else {
            self.interfaceBuilderIdentifier = nil
        }
        self.detail = detail
        if let location = logMessage.location as? DVTTextDocumentLocation {
            self.type = type
            if let analyzerMessage = logMessage as? IDEActivityLogAnalyzerEventStepMessage {
                self.title = analyzerMessage.description
            } else {
                self.title = logMessage.title
            }
            self.documentURL = location.documentURLString
            self.severity = logMessage.severity
            self.characterRangeEnd = location.characterRangeEnd
            self.characterRangeStart = location.characterRangeStart
            // Xcode reports line and column numbers using zero-based numbers
            self.startingLineNumber = Self.realLocationNumber(location.startingLineNumber)
            self.endingLineNumber = Self.realLocationNumber(location.endingLineNumber)
            self.startingColumnNumber = Self.realLocationNumber(location.startingColumnNumber)
            self.endingColumnNumber = Self.realLocationNumber(location.endingColumnNumber)
            self.clangFlag = clangFlag
        } else {
            self.type = type
            if let analyzerMessage = logMessage as? IDEActivityLogAnalyzerEventStepMessage {
                self.title = analyzerMessage.description
            } else {
                self.title = logMessage.title
            }
            self.documentURL = logMessage.location.documentURLString
            self.severity = logMessage.severity
            self.startingLineNumber = 0
            self.endingLineNumber = 0
            self.startingColumnNumber = 0
            self.endingColumnNumber = 0
            self.characterRangeEnd = 0
            self.characterRangeStart = 0
            self.clangFlag = clangFlag
        }
    }

    public func with(detail newDetail: String?) -> Notice {
        return Notice(type: type,
                      title: title,
                      clangFlag: clangFlag,
                      documentURL: documentURL,
                      severity: severity,
                      startingLineNumber: startingLineNumber,
                      endingLineNumber: endingLineNumber,
                      startingColumnNumber: startingColumnNumber,
                      endingColumnNumber: endingColumnNumber,
                      characterRangeEnd: characterRangeEnd,
                      characterRangeStart: characterRangeStart,
                      interfaceBuilderIdentifier: interfaceBuilderIdentifier,
                      detail: newDetail)
    }

    public func with(type newType: NoticeType) -> Notice {
        return Notice(type: newType,
                      title: title,
                      clangFlag: clangFlag,
                      documentURL: documentURL,
                      severity: severity,
                      startingLineNumber: startingLineNumber,
                      endingLineNumber: endingLineNumber,
                      startingColumnNumber: startingColumnNumber,
                      endingColumnNumber: endingColumnNumber,
                      characterRangeEnd: characterRangeEnd,
                      characterRangeStart: characterRangeStart,
                      interfaceBuilderIdentifier: interfaceBuilderIdentifier,
                      detail: detail)
    }

    /// Xcode reports the line and column number based on a zero-index location
    /// This adds a 1 to report the real location
    /// If there is no location, Xcode reports UIInt64.max. In that case this function
    /// doesn't do anything and returns the same number
    private static func realLocationNumber(_ number: UInt64) -> UInt64 {
        if number != UInt64.max {
            return number + 1
        }
        return number
    }
}

extension Notice: Hashable {
    public static func == (lhs: Notice, rhs: Notice) -> Bool {
        return
            lhs.characterRangeEnd == rhs.characterRangeEnd &&
            lhs.characterRangeStart == rhs.characterRangeStart &&
            lhs.detail == rhs.detail &&
            lhs.documentURL == rhs.documentURL &&
            lhs.endingColumnNumber == rhs.endingColumnNumber &&
            lhs.endingLineNumber == rhs.endingLineNumber &&
            lhs.startingColumnNumber == rhs.startingColumnNumber &&
            lhs.startingLineNumber == rhs.startingLineNumber &&
            lhs.title == rhs.title &&
            lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(characterRangeEnd)
        hasher.combine(characterRangeStart)
        hasher.combine(detail)
        hasher.combine(documentURL)
        hasher.combine(endingColumnNumber)
        hasher.combine(endingLineNumber)
        hasher.combine(startingColumnNumber)
        hasher.combine(startingLineNumber)
        hasher.combine(title)
        hasher.combine(type)
    }
}

import Foundation

/// Represents the time it took to the Swift Compiler to compile a function
public struct SwiftFunctionTime: Encodable, Equatable {
    /// URL of the file where the function is
    public let file: String

    /// Duration in Miliseconds
    public let durationMS: Double

    /// Line number where the function is declared
    public let startingLine: Int

    /// Column number where the function is declared
    public let startingColumn: Int

    /// function signature
    public let signature: String

    /// Number of occurences this function is compiled during the build
    public let occurrences: Int

}

import Foundation

extension BuildStep {

    func with(documentURL newDocumentURL: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: newDocumentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes
        )
    }

    func with(title newTitle: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: newTitle,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(signature newSignature: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: newSignature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(errors newErrors: [Notice]?, notes newNotes: [Notice]?, warnings newWarnings: [Notice]?) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: newWarnings?.count ?? 0,
                         errorCount: newErrors?.count ?? 0,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: newWarnings,
                         errors: newErrors,
                         notes: newNotes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func withFilteredNotices() -> BuildStep {
        let filteredNotes = filterNotices(notes)
        let filteredWarnings = filterNotices(warnings)
        let filtereredErrors = filterNotices(errors)
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: filteredWarnings?.count ?? 0,
                         errorCount: filtereredErrors?.count ?? 0,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: filteredWarnings,
                         errors: filtereredErrors,
                         notes: filteredNotes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(subSteps newSubSteps: [BuildStep]) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: newSubSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(newCompilationEndTimestamp: Double,
              andCompilationDuration newCompilationDuration: Double) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: newCompilationEndTimestamp,
                         compilationDuration: newCompilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(identifier newIdentifier: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: newIdentifier,
                         parentIdentifier: parentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    func with(parentIdentifier newParentIdentifier: String) -> BuildStep {
        return BuildStep(type: type,
                         machineName: machineName,
                         buildIdentifier: buildIdentifier,
                         identifier: identifier,
                         parentIdentifier: newParentIdentifier,
                         domain: domain,
                         title: title,
                         signature: signature,
                         startDate: startDate,
                         endDate: endDate,
                         startTimestamp: startTimestamp,
                         endTimestamp: endTimestamp,
                         duration: duration,
                         detailStepType: detailStepType,
                         buildStatus: buildStatus,
                         schema: schema,
                         subSteps: subSteps,
                         warningCount: warningCount,
                         errorCount: errorCount,
                         architecture: architecture,
                         documentURL: documentURL,
                         warnings: warnings,
                         errors: errors,
                         notes: notes,
                         swiftFunctionTimes: swiftFunctionTimes,
                         fetchedFromCache: fetchedFromCache,
                         compilationEndTimestamp: compilationEndTimestamp,
                         compilationDuration: compilationDuration,
                         clangTimeTraceFile: clangTimeTraceFile,
                         linkerStatistics: linkerStatistics,
                         swiftTypeCheckTimes: swiftTypeCheckTimes)
    }

    private func filterNotices(_ notices: [Notice]?) -> [Notice]? {
        guard let notices = notices else {
            return nil
        }
        return self.documentURL.isEmpty ? [] : notices
    }
}

import Foundation

public extension BuildStep {

    /// Flattens a group of swift compilations steps.
    ///
    /// When a Swift module is compiled with `whole module` option
    /// The parsed log looks like:
    /// - CompileSwiftTarget
    ///     - CompileSwift
    ///         - CompileSwift file1.swift
    ///         - CompileSwift file2.swift
    /// This tasks removes the intermediate CompileSwift step and moves the substeps
    /// to the root:
    /// - CompileSwiftTarget
    ///     - CompileSwift file1.swift
    ///     - CompileSwift file2.swift
    /// - Returns: The build step with its swift substeps at the root level, and intermediate CompileSwift step removed.
    func moveSwiftStepsToRoot() -> BuildStep {
        var updatedSubSteps = subSteps
        for (index, subStep) in subSteps.enumerated() {
            if subStep.detailStepType == .swiftCompilation && subStep.subSteps.count > 0 {
                updatedSubSteps.remove(at: index)
                updatedSubSteps.append(contentsOf: subStep.subSteps)
            }
        }
        return with(subSteps: updatedSubSteps)
    }

}

import Foundation

extension String {

    func substring(_ range: NSRange) -> String {
        guard let stringRange = Range(range, in: self) else {
            return ""
        }
        return String(self[stringRange])
    }

}

import Foundation

/// Functions to parser Notices from `IDELogSection` and `IDELogMessage`
extension Notice {

    /// Parses an `IDEActivityLogSection` looking for Warnings, Errors and Notes in its `IDEActivityLogMessage`.
    /// Uses the `categoryIdent` of `IDEActivityLogMessage` to categorize them.
    /// For CLANG warnings, it parses the `IDEActivityLogSection` text property looking for a *-W-warning-name* pattern
    /// - parameter logSection: An `IDEActivityLogSection`
    /// - parameter forType: The `DetailStepType` of the logSection
    /// - parameter truncLargeIssues: If true, if a task have more than 100 `Notice`, will be truncated to 100
    /// - returns: An Array of `Notice`
    public static func parseFromLogSection(_ logSection: IDEActivityLogSection,
                                           forType type: DetailStepType,
                                           truncLargeIssues: Bool)
        -> [Notice] {
        var logSection = logSection
        if truncLargeIssues && logSection.messages.count > 100 {
            logSection = self.logSectionWithTruncatedIssues(logSection: logSection)
        }
        // we look for clangWarnings parsing the text of the logSection
        let clangWarningsFlags = self.parseClangWarningFlags(text: logSection.text)
        let clangWarnings = self.parseClangWarnings(clangFlags: clangWarningsFlags, logSection: logSection)

        // Remove the messages that were categorized as clangWarnings
        let remainingLogMessages = logSection.messages.filter { message in
            return clangWarnings.contains { $0.title == message.title } == false
        }
        // parse details for Swift issues
        let swiftErrorDetails = parseSwiftIssuesDetailsByLocation(logSection.text)
        // we look for analyzer warnings, swift warnings, notes and errors
        return clangWarnings + remainingLogMessages.compactMap { message -> [Notice]? in
            if let resultMessage = message as? IDEActivityLogAnalyzerResultMessage {
                return resultMessage.subMessages.compactMap {
                    if let stepMessage = $0 as? IDEActivityLogAnalyzerEventStepMessage {
                        return Notice(withType: .analyzerWarning, logMessage: stepMessage)
                    }
                    return nil
                }
            }
            // Special case, Interface builder warning can only be spotted by checking the whole text of the
            // log section
            let noticeTypeTitle = message.categoryIdent.isEmpty ? logSection.text : message.categoryIdent
            if var notice = Notice(withType: NoticeType.fromTitle(noticeTypeTitle),
                                   logMessage: message,
                                   detail: logSection.text) {
                // Add the right details to Swift errors
                if notice.type == NoticeType.swiftError || notice.type == .swiftWarning {
                    // Special case, if Swiftc fails for a whole module,
                    // we don't have location and the detail already has
                    // enough information
                    let noticeDetail = notice.detail ?? ""
                    if noticeDetail.starts(with: "error:") == false {
                        var errorLocation = notice.documentURL.replacingOccurrences(of: "file://", with: "")
                        errorLocation += ":\(notice.startingLineNumber):\(notice.startingColumnNumber):"
                        // do not report error in a file that it does not belong to (we'll ended
                        // up having duplicated errors)
                        if !logSection.location.documentURLString.isEmpty
                            && logSection.location.documentURLString != notice.documentURL {
                            return nil
                        }
                        notice = notice.with(detail: swiftErrorDetails[errorLocation])
                    }
                }

                // Handle special cases

                if isDeprecatedWarning(type: notice.type, text: notice.title, clangFlags: notice.clangFlag) {
                    return [notice.with(type: .deprecatedWarning)]
                }
                // Ld command errors
                if notice.type == .error && type == .linker {
                    return [notice.with(type: .linkerError)]
                }
                // Build phase's script errors
                if notice.type == .scriptPhaseError {
                    // Decorate script phase error with the signature that contains the name of the
                    // phase and the target
                    return [notice.with(detail: "\(notice.detail ?? "") \(logSection.signature)")]
                }
                return [notice]
            }
            return nil
        }.reduce([Notice]()) { flatten, notices -> [Notice] in
            flatten + notices
        }
    }

    /// Xcode reports the details of Swift errors and warnings as a mixed text with all the errors in a
    /// compilation unit in the same Text. This functions parses.
    /// - parameter text: The LogSection.text with the error details
    /// - returns: A Dictionary where the keys are the error location in the form pathToFile:line:column:
    /// and the values are the error details for that location
    public static func parseSwiftIssuesDetailsByLocation(_ text: String) -> [String: String] {
        return text
            .split(separator: "\r")
            .reduce([]) { (details, line) -> [String] in
                var details = details
                if line.contains(": error:") || line.contains(": warning:") {
                    details.append(String(line))
                } else {
                    guard let current = details.last else {
                        return details
                    }
                    details.removeLast()
                    details.append("\(current)\n\(line)")
                }
                return details
        }
        .reduce([String: String]()) { (detailsByLoc, detail) -> [String: String] in
            let range: Range<String.Index>?
            if detail.contains(": error:") {
                range = detail.range(of: ": error:")
            } else {
                range = detail.range(of: ": warning:")
            }
            if let range = range {
                let location = detail[...range.lowerBound]
                var detailsByLoc = detailsByLoc
                detailsByLoc[String(location)] = detail
                return detailsByLoc
            }
            return detailsByLoc
        }
    }

    /// Parses the text of a IDELogSection looking for the pattern [-Wwarning-type]
    /// that means there was a clang warning.
    /// - parameter text: IDELogSection text property
    /// - returns: A list of clang warning flags found in the text, like -Wunused-function
    private static func parseClangWarningFlags(text: String) -> [String]? {
        guard let clangWarningRegexp = Notice.clangWarningRegexp else {
            return nil
        }
        let range = NSRange(location: 0, length: text.count)
        let matches = clangWarningRegexp.matches(in: text, options: .reportCompletion, range: range)
        return matches.map { result -> String in
            String(text.substring(result.range))
        }
    }

    private static func parseClangWarnings(clangFlags: [String]?, logSection: IDEActivityLogSection) -> [Notice] {
        guard let clangFlags = clangFlags else {
            return [Notice]()
        }
        return zip(logSection.messages, clangFlags)
            .compactMap { (message, warningFlag) -> Notice? in
                // If the warning is treated as error, we marked the issue as error
                let type: NoticeType = warningFlag.contains("-Werror") ? .clangError : .clangWarning
                let notice = Notice(withType: type, logMessage: message, clangFlag: warningFlag)

                if let notice = notice,
                    isDeprecatedWarning(type: type, text: notice.title, clangFlags: warningFlag) {
                    // Fixes a bug where Xcode logs add more than one message to report one
                    // deprecation warning. Only one has the right documentURL
                    if notice.documentURL != logSection.location.documentURLString {
                        return nil
                    }
                    return notice.with(type: .deprecatedWarning)
                }
                return notice
        }
    }

    private static func isDeprecatedWarning(type: NoticeType, text: String, clangFlags: String?) -> Bool {
        // Mark clang deprecated flags (https://clang.llvm.org/docs/DiagnosticsReference.html)
        if let clangFlags = clangFlags, clangFlags.contains("-Wdeprecated") {
            return true
        }
        // Support for Swift and ObjC code marked as deprecated
        if type == .swiftError || type == .swiftWarning || type == .projectWarning || type == .clangWarning
            || type == .note {
            return text.contains(" deprecated:")
                || text.contains("was deprecated in")
                || text.contains("has been deprecated")
                || text.contains("is deprecated")
        }
        return false
    }

    private static func logSectionWithTruncatedIssues(logSection: IDEActivityLogSection) -> IDEActivityLogSection {
        let issuesKept = min(99, logSection.messages.count)
        var truncatedMessages = Array(logSection.messages[0..<issuesKept])
        truncatedMessages.append(getTruncatedIssuesWarning(logSection: logSection, issuesKept: issuesKept))
        return logSection.with(messages: truncatedMessages)
    }

    private static func getTruncatedIssuesWarning(logSection: IDEActivityLogSection, issuesKept: Int)
    -> IDEActivityLogMessage {
        let title = "Warning: \(logSection.messages.count - issuesKept) issues were truncated"
        return IDEActivityLogMessage(title: title,
                                     shortTitle: "",
                                     timeEmitted: 0,
                                     rangeEndInSectionText: 0,
                                     rangeStartInSectionText: 0,
                                     subMessages: [],
                                     severity: 0,
                                     type: "",
                                     location: DVTDocumentLocation(documentURLString: "", timestamp: 0),
                                     categoryIdent: "Warning",
                                     secondaryLocations: [],
                                     additionalDescription: "")
    }
}

import Foundation

extension IDEActivityLogSection {

    func with(messages newMessages: [IDEActivityLogMessage]) -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: self.sectionType,
                                     domainType: self.domainType,
                                     title: self.title,
                                     signature: self.signature,
                                     timeStartedRecording: self.timeStartedRecording,
                                     timeStoppedRecording: self.timeStoppedRecording,
                                     subSections: self.subSections,
                                     text: self.text,
                                     messages: newMessages,
                                     wasCancelled: self.wasCancelled,
                                     isQuiet: self.isQuiet,
                                     wasFetchedFromCache: self.wasFetchedFromCache,
                                     subtitle: self.subtitle,
                                     location: self.location,
                                     commandDetailDesc: self.commandDetailDesc,
                                     uniqueIdentifier: self.uniqueIdentifier,
                                     localizedResultString: self.localizedResultString,
                                     xcbuildSignature: self.xcbuildSignature,
                                     attachments: self.attachments,
                                     unknown: self.unknown)
    }

}

import Foundation

/// Parses an xcactivitylog into a Swift representation
/// Used by the Dump command
// swiftlint:disable type_body_length
// swiftlint:disable file_length
public class ActivityParser {

    /// Some IDEActivitlyLog have an extra int at the end
    /// This flag is turn on if is the case, so the parse will take
    /// that into account
    var isCommandLineLog = false

    /// The version of the parsed `IDEActivityLog`.
    /// Used to skip parsing of the `IDEActivityLogSectionAttachment` list on version less than 11.
    var logVersion: Int8?

    public init() {}

    /// Parses the xcacticitylog argument into a `IDEActivityLog`
    /// - parameter logURL: `URL` of the xcactivitylog
    /// - parameter redacted: If true, the username will be replaced
    /// in the file paths inside the logs for the word `redacted`.
    /// This flag is useful to preserve the privacy of the users.
    /// - parameter withoutBuildSpecificInformation: If true, build specific
    /// information will be removed from the logs (for example `bolnckhlbzxpxoeyfujluasoupft`
    /// will be removed from  `DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build`).
    /// This flag is useful for grouping logs by its content.
    /// - returns: An instance of `IDEActivityLog1
    /// - throws: An Error if the file is not valid.
    public func parseActivityLogInURL(_ logURL: URL,
                                      redacted: Bool,
                                      withoutBuildSpecificInformation: Bool) throws -> IDEActivityLog {
        let tokens = try getTokens(logURL, redacted: redacted,
                                   withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        return try parseIDEActiviyLogFromTokens(tokens)
    }

    public func parseIDEActiviyLogFromTokens(_ tokens: [Token]) throws -> IDEActivityLog {
        var iterator = tokens.makeIterator()
        let logVersion = Int8(try parseAsInt(token: iterator.next()))
        self.logVersion = logVersion
        return IDEActivityLog(version: logVersion,
                              mainSection: try parseLogSection(iterator: &iterator))
    }

    public func parseDVTTextDocumentLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> DVTTextDocumentLocation {
        return DVTTextDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                       timestamp: try parseAsDouble(token: iterator.next()),
                                       startingLineNumber: try parseAsInt(token: iterator.next()),
                                       startingColumnNumber: try parseAsInt(token: iterator.next()),
                                       endingLineNumber: try parseAsInt(token: iterator.next()),
                                       endingColumnNumber: try parseAsInt(token: iterator.next()),
                                       characterRangeEnd: try parseAsInt(token: iterator.next()),
                                       characterRangeStart: try parseAsInt(token: iterator.next()),
                                       locationEncoding: try parseAsInt(token: iterator.next()))
    }

    public func parseDVTDocumentLocation(iterator: inout IndexingIterator<[Token]>) throws -> DVTDocumentLocation {
        return DVTDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                       timestamp: try parseAsDouble(token: iterator.next()))
    }

    public func parseIDEActivityLogMessage(iterator: inout IndexingIterator<[Token]>) throws -> IDEActivityLogMessage {
        return IDEActivityLogMessage(title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()))
    }

    public func parseIDEActivityLogSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSection {
        return IDEActivityLogSection(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                     domainType: try parseAsString(token: iterator.next()),
                                     title: try parseAsString(token: iterator.next()),
                                     signature: try parseAsString(token: iterator.next()),
                                     timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                     timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                     subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                     text: try parseAsString(token: iterator.next()),
                                     messages: try parseMessages(iterator: &iterator),
                                     wasCancelled: try parseBoolean(token: iterator.next()),
                                     isQuiet: try parseBoolean(token: iterator.next()),
                                     wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                     subtitle: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     commandDetailDesc: try parseAsString(token: iterator.next()),
                                     uniqueIdentifier: try parseAsString(token: iterator.next()),
                                     localizedResultString: try parseAsString(token: iterator.next()),
                                     xcbuildSignature: try parseAsString(token: iterator.next()),
                                     attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                     unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0)
    }

    public func parseIDEActivityLogUnitTestSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogUnitTestSection {
            return IDEActivityLogUnitTestSection(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                         domainType: try parseAsString(token: iterator.next()),
                                         title: try parseAsString(token: iterator.next()),
                                         signature: try parseAsString(token: iterator.next()),
                                         timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                         timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                         subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                         text: try parseAsString(token: iterator.next()),
                                         messages: try parseMessages(iterator: &iterator),
                                         wasCancelled: try parseBoolean(token: iterator.next()),
                                         isQuiet: try parseBoolean(token: iterator.next()),
                                         wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                         subtitle: try parseAsString(token: iterator.next()),
                                         location: try parseDocumentLocation(iterator: &iterator),
                                         commandDetailDesc: try parseAsString(token: iterator.next()),
                                         uniqueIdentifier: try parseAsString(token: iterator.next()),
                                         localizedResultString: try parseAsString(token: iterator.next()),
                                         xcbuildSignature: try parseAsString(token: iterator.next()),
                                         attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                         unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0,
                                         testsPassedString: try parseAsString(token: iterator.next()),
                                         durationString: try parseAsString(token: iterator.next()),
                                         summaryString: try parseAsString(token: iterator.next()),
                                         suiteName: try parseAsString(token: iterator.next()),
                                         testName: try parseAsString(token: iterator.next()),
                                         performanceTestOutputString: try parseAsString(token: iterator.next()))
    }

    public func parseDBGConsoleLog(iterator: inout IndexingIterator<[Token]>)
        throws -> DBGConsoleLog {
            return DBGConsoleLog(sectionType: Int8(try parseAsInt(token: iterator.next())),
                                                 domainType: try parseAsString(token: iterator.next()),
                                                 title: try parseAsString(token: iterator.next()),
                                                 signature: try parseAsString(token: iterator.next()),
                                                 timeStartedRecording: try parseAsDouble(token: iterator.next()),
                                                 timeStoppedRecording: try parseAsDouble(token: iterator.next()),
                                                 subSections: try parseIDEActivityLogSections(iterator: &iterator),
                                                 text: try parseAsString(token: iterator.next()),
                                                 messages: try parseMessages(iterator: &iterator),
                                                 wasCancelled: try parseBoolean(token: iterator.next()),
                                                 isQuiet: try parseBoolean(token: iterator.next()),
                                                 wasFetchedFromCache: try parseBoolean(token: iterator.next()),
                                                 subtitle: try parseAsString(token: iterator.next()),
                                                 location: try parseDocumentLocation(iterator: &iterator),
                                                 commandDetailDesc: try parseAsString(token: iterator.next()),
                                                 uniqueIdentifier: try parseAsString(token: iterator.next()),
                                                 localizedResultString: try parseAsString(token: iterator.next()),
                                                 xcbuildSignature: try parseAsString(token: iterator.next()),
                                                 // swiftlint:disable:next line_length
                                                 attachments: try parseIDEActivityLogSectionAttachments(iterator: &iterator),
                                                 // swiftlint:disable:next line_length
                                                 unknown: isCommandLineLog ? Int(try parseAsInt(token: iterator.next())) : 0,
                                                 logConsoleItems: try parseIDEConsoleItems(iterator: &iterator)
                                                 )
    }

    public func parseIDEActivityLogAnalyzerResultMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerResultMessage {
        return IDEActivityLogAnalyzerResultMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     resultType: try parseAsString(token: iterator.next()),
                                     keyEventIndex: try parseAsInt(token: iterator.next()))
    }

    public func parseIDEActivityLogAnalyzerEventStepMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerEventStepMessage {
        return IDEActivityLogAnalyzerEventStepMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     parentIndex: try parseAsInt(token: iterator.next()),
                                     description: try parseAsString(token: iterator.next()),
                                     callDepth: try parseAsInt(token: iterator.next()))
    }

    public func parseIDEActivityLogAnalyzerControlFlowStepMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerControlFlowStepMessage {
        return IDEActivityLogAnalyzerControlFlowStepMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     parentIndex: try parseAsInt(token: iterator.next()),
                                     endLocation: try parseDocumentLocation(iterator: &iterator),
                                     edges: try parseStepEdges(iterator: &iterator))
    }

    public func parseIDEActivityLogAnalyzerControlFlowStepEdge(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogAnalyzerControlFlowStepEdge {
        return IDEActivityLogAnalyzerControlFlowStepEdge(
                                     startLocation: try parseDocumentLocation(iterator: &iterator),
                                     endLocation: try parseDocumentLocation(iterator: &iterator))
    }

    public func parseIDEActivityLogActionMessage(iterator: inout IndexingIterator<[Token]>) throws
        -> IDEActivityLogActionMessage {
        return IDEActivityLogActionMessage(
                                     title: try parseAsString(token: iterator.next()),
                                     shortTitle: try parseAsString(token: iterator.next()),
                                     timeEmitted: try Double(parseAsInt(token: iterator.next())),
                                     rangeEndInSectionText: try parseAsInt(token: iterator.next()),
                                     rangeStartInSectionText: try parseAsInt(token: iterator.next()),
                                     subMessages: try parseMessages(iterator: &iterator),
                                     severity: Int(try parseAsInt(token: iterator.next())),
                                     type: try parseAsString(token: iterator.next()),
                                     location: try parseDocumentLocation(iterator: &iterator),
                                     categoryIdent: try parseAsString(token: iterator.next()),
                                     secondaryLocations: try parseDocumentLocations(iterator: &iterator),
                                     additionalDescription: try parseAsString(token: iterator.next()),
                                     action: try parseAsString(token: iterator.next()))
    }

    private func getTokens(_ logURL: URL,
                           redacted: Bool,
                           withoutBuildSpecificInformation: Bool) throws -> [Token] {
        let logLoader = LogLoader()
        var tokens: [Token] = []
        #if os(Linux)
        let content = try logLoader.loadFromURL(logURL)
        let lexer = Lexer(filePath: logURL.path)
        tokens = try lexer.tokenize(contents: content,
                                        redacted: redacted,
                                        withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        #else
        try autoreleasepool {
            let content = try logLoader.loadFromURL(logURL)
            let lexer = Lexer(filePath: logURL.path)
            tokens = try lexer.tokenize(contents: content,
                                            redacted: redacted,
                                            withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
        #endif
        return tokens
    }

    private func parseMessages(iterator: inout IndexingIterator<[Token]>) throws -> [IDEActivityLogMessage] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Parsing [IDEActivityLogMessage]")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var messages = [IDEActivityLogMessage]()
            for _ in 0..<count {
                let message = try parseLogMessage(iterator: &iterator)
                messages.append(message)
            }
            return messages
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEActivityLogMessage \(listToken)")
        }
    }

    private func parseDocumentLocations(iterator: inout IndexingIterator<[Token]>) throws -> [DVTDocumentLocation] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing [DocumentLocation]")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var locations = [DVTDocumentLocation]()
            for _ in 0..<count {
                let location = try parseDocumentLocation(iterator: &iterator)
                locations.append(location)
            }
            return locations
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of DocumentLocation \(listToken)")
        }
    }

    public func parseDocumentLocation(iterator: inout IndexingIterator<[Token]>) throws -> DVTDocumentLocation {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        if case Token.null = classRefToken {
            return DVTDocumentLocation(documentURLString: "", timestamp: 0.0)
        }
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing DocumentLocation \(classRefToken)")
        }
        if className == String(describing: DVTTextDocumentLocation.self) {
            return try parseDVTTextDocumentLocation(iterator: &iterator)
        } else if className == String(describing: DVTDocumentLocation.self)  ||
            className == "Xcode3ProjectDocumentLocation" || className == "IDELogDocumentLocation" {
            return try parseDVTDocumentLocation(iterator: &iterator)
        } else if className == String(describing: IBDocumentMemberLocation.self) {
            return try parseIBDocumentMemberLocation(iterator: &iterator)
        } else if className == String(describing: DVTMemberDocumentLocation.self) {
            return try parseDVTMemberDocumentLocation(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing DocumentLocation \(className)")
    }

    private func parseLogMessage(iterator: inout IndexingIterator<[Token]>) throws -> IDEActivityLogMessage {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard
            case Token.classNameRef(let className) = classRefToken
        else {
            throw XCLogParserError.parseError("Unexpected token found parsing IDEActivityLogMessage \(classRefToken)")
        }
        if className == String(describing: IDEActivityLogMessage.self) ||
            className == "IDEClangDiagnosticActivityLogMessage" ||
            className == "IDEDiagnosticActivityLogMessage" {
            return try parseIDEActivityLogMessage(iterator: &iterator)
        }
        if className ==  String(describing: IDEActivityLogAnalyzerResultMessage.self) {
            return try parseIDEActivityLogAnalyzerResultMessage(iterator: &iterator)
        }
        if className ==  String(describing: IDEActivityLogAnalyzerControlFlowStepMessage.self) {
            return try parseIDEActivityLogAnalyzerControlFlowStepMessage(iterator: &iterator)
        }
        if className == String(describing: IDEActivityLogAnalyzerEventStepMessage.self) {
            return try parseIDEActivityLogAnalyzerEventStepMessage(iterator: &iterator)
        }
        if className == String(describing: IDEActivityLogActionMessage.self) {
            return try parseIDEActivityLogActionMessage(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing IDEActivityLogMessage \(className)")
    }

    private func parseLogSectionAttachment(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSectionAttachment {
            let classRefToken = try getClassRefToken(iterator: &iterator)
            guard case Token.classNameRef(let className) = classRefToken else {
                throw XCLogParserError.parseError("Unexpected token found parsing " +
                                                  "IDEActivityLogSectionAttachment \(classRefToken)")
            }

            if className == "IDEFoundation.\(String(describing: IDEActivityLogSectionAttachment.self))" {
                let jsonType = IDEActivityLogSectionAttachment.BuildOperationTaskMetrics.self
                return try IDEActivityLogSectionAttachment(identifier: try parseAsString(token: iterator.next()),
                                                           majorVersion: try parseAsInt(token: iterator.next()),
                                                           minorVersion: try parseAsInt(token: iterator.next()),
                                                           metrics: try parseAsJson(token: iterator.next(),
                                                                                    type: jsonType))
            }
            throw XCLogParserError.parseError("Unexpected className found parsing IDEConsoleItem \(className)")
    }

    private func parseLogSection(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogSection {
        var classRefToken = try getClassRefToken(iterator: &iterator)
        // if we found and extra int field, we should treat this as an commandLineLog
        if case Token.int(_) = classRefToken {
            isCommandLineLog = true
            classRefToken = try getClassRefToken(iterator: &iterator)
        }
        guard
            case Token.classNameRef(let className) = classRefToken
            else {
                throw XCLogParserError.parseError("Unexpected token found parsing " +
                                                  "IDEActivityLogSection \(classRefToken)")
        }
        if className == String(describing: IDEActivityLogSection.self) {
            return try parseIDEActivityLogSection(iterator: &iterator)
        }
        if className == "IDECommandLineBuildLog" ||
            className == "IDEActivityLogMajorGroupSection" ||
            className == "IDEActivityLogCommandInvocationSection" {
            return try parseIDEActivityLogSection(iterator: &iterator)
        }
        if className == "IDEActivityLogUnitTestSection" {
            return try parseIDEActivityLogUnitTestSection(iterator: &iterator)
        }
        if className == String(describing: DBGConsoleLog.self) {
            return try parseDBGConsoleLog(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing IDEActivityLogSection \(className)")
    }

    private func getClassRefToken(iterator: inout IndexingIterator<[Token]>) throws -> Token {
        guard let classRefToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef")
        }
        // The first time there is a classRef of an specific Type,
        // There is a className before that defines the Type
        if case Token.className = classRefToken {
            guard let classRefToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef")
            }
            if case Token.classNameRef = classRefToken {
                return classRefToken
            } else {
                throw XCLogParserError.parseError("Unexpected EOF parsing ClassRef: \(classRefToken)")
            }

        }
        return classRefToken
    }

    private func parseIDEActivityLogSections(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogSection] {
            guard let listToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEActivityLogSection")
            }
            switch listToken {
            case .null:
                return []
            case .list(let count):
                var sections = [IDEActivityLogSection]()
                for _ in 0..<count {
                    let section = try parseLogSection(iterator: &iterator)
                    sections.append(section)
                }
                return sections
            default:
                throw XCLogParserError.parseError("Unexpected token parsing array of " +
                                                  "IDEActivityLogSection: \(listToken)")
            }
    }

    private func parseIDEActivityLogSectionAttachments(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogSectionAttachment] {
            guard let logVersion else {
                throw XCLogParserError.parseError("Log version not parsed before parsing " +
                                                  "array of IDEActivityLogSectionAttachment")
            }
            /// The list of IDEActivityLogSectionAttachment was introduced with version 11
            guard logVersion >= 11 else {
                return []
            }
            guard let listToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEActivityLogSectionAttachment")
            }
            switch listToken {
            case .null:
                return []
            case .list(let count):
                var sections = [IDEActivityLogSectionAttachment]()
                for _ in 0..<count {
                    let section = try parseLogSectionAttachment(iterator: &iterator)
                    sections.append(section)
                }
                return sections
            default:
                throw XCLogParserError.parseError("Unexpected token parsing array of " +
                                                  "IDEActivityLogSectionAttachment: \(listToken)")
            }
    }

    private func parseIDEConsoleItem(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEConsoleItem? {
            let classRefToken = try getClassRefToken(iterator: &iterator)
            if case Token.null = classRefToken {
               return nil
            }
            guard case Token.classNameRef(let className) = classRefToken else {
                throw XCLogParserError.parseError("Unexpected token found parsing IDEConsoleItem \(classRefToken)")
            }

            if className == String(describing: IDEConsoleItem.self) {
                return IDEConsoleItem(adaptorType: try parseAsInt(token: iterator.next()),
                                      content: try parseAsString(token: iterator.next()),
                                      kind: try parseAsInt(token: iterator.next()),
                                      timestamp: try parseAsDouble(token: iterator.next()))
            }
            throw XCLogParserError.parseError("Unexpected className found parsing IDEConsoleItem \(className)")
    }

    private func parseIDEConsoleItems(iterator: inout IndexingIterator<[Token]>) throws -> [IDEConsoleItem] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEConsoleItem")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var items = [IDEConsoleItem]()
            for _ in 0..<count {
                if let item = try parseIDEConsoleItem(iterator: &iterator) {
                    items.append(item)
                }
            }
            return items
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEConsoleItem: \(listToken)")
        }
    }

    private func parseStepEdge(iterator: inout IndexingIterator<[Token]>)
        throws -> IDEActivityLogAnalyzerControlFlowStepEdge {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing " +
                "IDEActivityLogAnalyzerControlFlowStepEdge \(classRefToken)")
        }

        if className == String(describing: IDEActivityLogAnalyzerControlFlowStepEdge.self) {
            return try parseIDEActivityLogAnalyzerControlFlowStepEdge(iterator: &iterator)
        }
        throw XCLogParserError.parseError("Unexpected className found parsing " +
            "IDEActivityLogAnalyzerControlFlowStepEdge \(className)")
    }

    private func parseStepEdges(iterator: inout IndexingIterator<[Token]>)
        throws -> [IDEActivityLogAnalyzerControlFlowStepEdge] {
        guard let listToken = iterator.next() else {
            throw XCLogParserError.parseError("Unexpected EOF parsing array of IDEConsoleItem")
        }
        switch listToken {
        case .null:
            return []
        case .list(let count):
            var items = [IDEActivityLogAnalyzerControlFlowStepEdge]()
            for _ in 0..<count {
                items.append(try parseStepEdge(iterator: &iterator))
            }
            return items
        default:
            throw XCLogParserError.parseError("Unexpected token parsing array of IDEConsoleItem: \(listToken)")
        }
    }

    private func parseIBDocumentMemberLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> IBDocumentMemberLocation {
            return IBDocumentMemberLocation(documentURLString: try parseAsString(token: iterator.next()),
                                            timestamp: try parseAsDouble(token: iterator.next()),
                                            memberIdentifier: try parseIBMemberID(iterator: &iterator),
                                            attributeSearchLocation:
                                                try parseIBAttributeSearchLocation(iterator: &iterator))
    }

    private func parseIBMemberID(iterator: inout IndexingIterator<[Token]>)
        throws -> IBMemberID {
        let classRefToken = try getClassRefToken(iterator: &iterator)
        guard case Token.classNameRef(let className) = classRefToken else {
            throw XCLogParserError.parseError("Unexpected token found parsing " +
                "IBMemberID \(classRefToken)")
        }

        if className == String(describing: IBMemberID.self) {
            return IBMemberID(memberIdentifier: try parseAsString(token: iterator.next()))
        }
        throw XCLogParserError.parseError("Unexpected className found parsing " +
            "IBMemberID \(className)")
    }

    private func parseIBAttributeSearchLocation(iterator: inout IndexingIterator<[Token]>)
        throws -> IBAttributeSearchLocation? {
            guard let nextToken = iterator.next() else {
                throw XCLogParserError.parseError("Unexpected EOF parsing IBAttributeSearchLocation")
            }
            if case Token.null = nextToken {
                return nil
            }
            throw XCLogParserError.parseError("Unexpected Token parsing IBAttributeSearchLocation: \(nextToken)")
    }

    private func parseAsString(token: Token?) throws -> String {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing String")
        }
        switch token {
        case .string(let string):
            return string.trimmingCharacters(in: .whitespacesAndNewlines)
        case .null:
            return ""
        default:
            throw XCLogParserError.parseError("Unexpected token parsing String: \(token)")
        }
    }

    private func parseAsJson<T: Decodable>(token: Token?, type: T.Type) throws -> T? {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing JSON String")
        }
        switch token {
        case .json(let string):
            guard let data = string.data(using: .utf8) else {
                throw XCLogParserError.parseError("Unexpected JSON string \(string)")
            }
            return try JSONDecoder().decode(type, from: data)
        case .null:
            return nil
        default:
            throw XCLogParserError.parseError("Unexpected token parsing JSON String: \(token)")
        }
    }

    private func parseAsInt(token: Token?) throws -> UInt64 {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Int")
        }
        if case Token.int(let value) = token {
            return value
        }
        throw XCLogParserError.parseError("Unexpected token parsing Int: \(token))")
    }

    private func parseAsDouble(token: Token?) throws -> Double {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Double")
        }
        if case Token.double(let value) = token {
            return value
        }
        throw XCLogParserError.parseError("Unexpected token parsing Double: \(token)")
    }

    private func parseBoolean(token: Token?) throws -> Bool {
        guard let token = token else {
            throw XCLogParserError.parseError("Unexpected EOF parsing Bool")
        }
        if case Token.int(let value) = token {
            if value > 1 {
                throw XCLogParserError.parseError("Unexpected value parsing Bool: \(value)")
            }
            return value == 1
        }
        throw XCLogParserError.parseError("Unexpected token parsing Bool: \(token)")
    }

    private func parseDVTMemberDocumentLocation(iterator: inout IndexingIterator<[Token]>)
    throws -> DVTMemberDocumentLocation {
        return DVTMemberDocumentLocation(documentURLString: try parseAsString(token: iterator.next()),
                                         timestamp: try parseAsDouble(token: iterator.next()),
                                         member: try parseAsString(token: iterator.next()))
    }

}

import Foundation

public enum TokenType: String, CaseIterable {
    case int = "#"
    case className = "%"
    case classNameRef = "@"
    case string = "\""
    case double = "^"
    case null = "-"
    case list = "("
    case json = "*"

    static func all() -> String {
        return TokenType.allCases.reduce(String()) {
            return "\($0)\($1.rawValue)"
        }
    }
}

public enum Token: CustomDebugStringConvertible, Equatable {
    case int(UInt64)
    case className(String)
    case classNameRef(String)
    case string(String)
    case double(Double)
    case null
    case list(Int)
    case json(String)
}

extension Token {
    public var debugDescription: String {
        switch self {
        case .int(let value):
            return "[type: int, value: \(value)]"
        case .className(let name):
            return "[type: className, name: \"\(name)\"]"
        case .classNameRef(let name):
            return "[type: classNameRef, className: \"\(name)\"]"
        case .string(let value):
            return "[type: string, value: \"\(value)\"]"
        case .double(let value):
            return "[type: double, value: \(value)]"
        case .null:
            return "[type: nil]"
        case .list(let count):
            return "[type: list, count: \(count)]"
        case .json(let json):
            return "[type: json, value: \(json)]"
        }
    }
}

import Foundation

public enum XCLogParserError: LocalizedError {
    case invalidLogHeader(String)
    case invalidLine(String)
    case errorCreatingReport(String)
    case wrongLogManifestFile(String, String)
    case parseError(String)

    public var errorDescription: String? { return description }
}

extension XCLogParserError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidLogHeader(let path):
            return "The file in \(path) is not a valid SLF log"
        case .invalidLine(let line):
            return "The line \(line) doesn't seem like a valid SLF line"
        case .errorCreatingReport(let error):
            return "Can't create the report: \(error)"
        case .wrongLogManifestFile(let path, let error):
            return "There was an error reading the latest build time " +
            " from the file \(path). Error: \(error)"
        case .parseError(let message):
            return "Error parsing the log: \(message)"
        }
    }
}

import Foundation
import Gzip

public struct LogLoader {

    func loadFromURL(_ url: URL) throws -> String {
        do {
            let data = try Data(contentsOf: url)
            let unzipped = try data.gunzipped()
            let string: String? = unzipped.withUnsafeBytes { pointer in
                guard let charPointer = pointer
                    .assumingMemoryBound(to: CChar.self)
                    .baseAddress
                else {
                    return nil
                }

                return String(cString: charPointer, encoding: .ascii)
            }
            guard let contents = string else {
                throw LogError.readingFile(url.path)
            }
            return contents
        } catch {
            throw LogError.invalidFile(url.path)
        }
    }

}

import Foundation

/// Errors thrown by the LogFinder
public enum LogError: LocalizedError {
    case noDerivedDataFound
    case noLogFound(dir: String)
    case xcodeBuildError(String)
    case readingFile(String)
    case invalidFile(String)
    case noLogManifestFound(dir: String)
    case invalidLogManifest(String)

    public var errorDescription: String? { return description }

}

extension LogError: CustomStringConvertible {

    public var description: String {
        switch self {
        case .noDerivedDataFound:
            return "We couldn't find the derivedData directory. " +
            "If you use a custom derivedData directory, use the --derived_data option to pass it. "
        case .noLogFound(let dir):
            return "We couldn't find a log in the directory \(dir). " +
                "If the log is in a custom derivedData dir, use the --derived_data option. " +
                "You can also pass the full path to the xcactivity log with the --file option"
        case .xcodeBuildError(let error):
            return error
        case .readingFile(let path):
            return "Can't read file \(path)"
        case .invalidFile(let path):
            return "\(path) is not a valid xcactivitylog file"
        case .noLogManifestFound(let path):
            return "We couldn't find a logManifest in the path \(path). " +
            "If the LogManifest is in a custom derivedData directory, use the --derived_data option."
        case .invalidLogManifest(let path):
            return "\(path) is not a valid LogManifest file"
        }
    }

}

import Foundation

public final class Lexer {

    static let SLFHeader = "SLF"

    let typeDelimiters: CharacterSet
    let filePath: String
    var classNames = [String]()
    var userDirToRedact: String? {
        get {
            redactor.userDirToRedact
        }
        set {
            redactor.userDirToRedact = newValue
        }
    }
    private var redactor: LogRedactor

    public init(filePath: String) {
        self.filePath = filePath
        self.typeDelimiters = CharacterSet(charactersIn: TokenType.all())
        self.redactor = LexRedactor()
    }

    /// Tokenizes an xcactivitylog serialized in the `SLF` format
    /// - parameter contents: The contents of the .xcactivitylog
    /// - parameter redacted: If true, the user's directory will be replaced by `<redacted>`
    /// for privacy concerns.
    /// - parameter withoutBuildSpecificInformation: If true, build specific information will be removed from the logs.
    /// - returns: An array of all the `Token` in the log.
    /// - throws: An error if the document is not a valid SLF document
    public func tokenize(contents: String,
                         redacted: Bool,
                         withoutBuildSpecificInformation: Bool) throws -> [Token] {
        let scanner = Scanner(string: contents)
        guard scanSLFHeader(scanner: scanner) else {
            throw XCLogParserError.invalidLogHeader(filePath)
        }
        var tokens = [Token]()
        while !scanner.isAtEnd {
            guard let logTokens = scanSLFType(scanner: scanner,
                                              redacted: redacted,
                                              withoutBuildSpecificInformation: withoutBuildSpecificInformation),
                logTokens.isEmpty == false else {
                print(tokens)
                throw XCLogParserError.invalidLine(scanner.approximateLine)
            }
            tokens.append(contentsOf: logTokens)
        }
        return tokens
    }

    private func scanSLFHeader(scanner: Scanner) -> Bool {
        #if os(Linux)
        var format: String?
        #else
        var format: NSString?
        #endif
        return scanner.scanString(Lexer.SLFHeader, into: &format)
    }

    private func scanSLFType(scanner: Scanner, redacted: Bool, withoutBuildSpecificInformation: Bool) -> [Token]? {

        guard let payload = scanPayload(scanner: scanner) else {
            return nil
        }
        guard let tokenTypes = scanTypeDelimiter(scanner: scanner), tokenTypes.count > 0 else {
            return nil
        }

        return tokenTypes.compactMap { tokenType -> Token? in
            scanToken(scanner: scanner,
                      payload: payload,
                      tokenType: tokenType,
                      redacted: redacted,
                      withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
    }

    private func scanPayload(scanner: Scanner) -> String? {
        var payload: String = ""
        #if os(Linux)
        var char: String?
        #else
        var char: NSString?
        #endif
        let hexChars = "abcdef0123456789"
        while scanner.scanCharacters(from: CharacterSet(charactersIn: hexChars), into: &char),
              let char = char as String? {
            payload.append(char)
        }
        return payload
    }

    private func scanTypeDelimiter(scanner: Scanner) -> [TokenType]? {
        #if os(Linux)
        var delimiters: String?
        #else
        var delimiters: NSString?
        #endif
        if scanner.scanCharacters(from: typeDelimiters, into: &delimiters), let delimiters = delimiters {
            let delimiters = String(delimiters)
            if delimiters.count > 1 {
                // if we found a string, we discard other type delimiters because there are part of the string
                let tokenString = TokenType.string
                if let char = delimiters.first, tokenString.rawValue == String(char) {
                    scanner.scanLocation -= delimiters.count - 1
                    return [tokenString]
                }
            }
            // sometimes we found one or more nil list (-) next to the type delimiter
            // in that case we'll return the delimiter and one or more `Token.null`
            return delimiters.compactMap { character -> TokenType? in
                TokenType(rawValue: String(character))
            }
        }
        return nil
    }

    private func scanToken(scanner: Scanner,
                           payload: String,
                           tokenType: TokenType,
                           redacted: Bool,
                           withoutBuildSpecificInformation: Bool) -> Token? {
        switch tokenType {
        case .int:
            return handleIntTokenTypeCase(payload: payload)
        case .className:
            return handleClassNameTokenTypeCase(scanner: scanner,
                                                payload: payload,
                                                redacted: redacted,
                                                withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        case .classNameRef:
            return handleClassNameRefTokenTypeCase(payload: payload)
        case .string:
            return handleStringTokenTypeCase(scanner: scanner,
                                             payload: payload,
                                             redacted: redacted,
                                             withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        case .double:
            return handleDoubleTokenTypeCase(payload: payload)
        case .null:
            return .null
        case .list:
            return handleListTokenTypeCase(payload: payload)
        case .json:
            return handleJSONTokenTypeCase(scanner: scanner,
                                           payload: payload,
                                           redacted: redacted,
                                           withoutBuildSpecificInformation: withoutBuildSpecificInformation)
        }
    }

    private func handleIntTokenTypeCase(payload: String) -> Token? {
        guard let value = UInt64(payload) else {
            print("error parsing int")
            return nil
        }
        return .int(value)
    }

    private func handleClassNameTokenTypeCase(scanner: Scanner,
                                              payload: String,
                                              redacted: Bool,
                                              withoutBuildSpecificInformation: Bool) -> Token? {
        guard let className = scanString(length: payload,
                                         scanner: scanner,
                                         redacted: redacted,
                                         withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                            print("error parsing string")
                                            return nil
        }
        classNames.append(className)
        return .className(className)
    }

    private func handleClassNameRefTokenTypeCase(payload: String) -> Token? {
        guard let value = Int(payload) else {
            print("error parsing classNameRef")
            return nil
        }
        let element = value - 1
        let className = classNames[element]
        return .classNameRef(className)
    }

    private func handleStringTokenTypeCase(scanner: Scanner,
                                           payload: String,
                                           redacted: Bool,
                                           withoutBuildSpecificInformation: Bool) -> Token? {
        guard let content = scanString(length: payload,
                                       scanner: scanner,
                                       redacted: redacted,
                                       withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                        print("error parsing string")
                                        return nil
        }
        return .string(content)
    }

    private func handleJSONTokenTypeCase(scanner: Scanner,
                                         payload: String,
                                         redacted: Bool,
                                         withoutBuildSpecificInformation: Bool) -> Token? {
        guard let content = scanString(length: payload,
                                       scanner: scanner,
                                       redacted: redacted,
                                       withoutBuildSpecificInformation: withoutBuildSpecificInformation) else {
                                        print("error parsing string")
                                        return nil
        }
        return .json(content)
    }

    private func handleDoubleTokenTypeCase(payload: String) -> Token? {
        guard let double = hexToInt(payload) else {
            print("error parsing double")
            return nil
        }
        return .double(double)
    }

    private func handleListTokenTypeCase(payload: String) -> Token? {
        guard let value = Int(payload) else {
            print("error parsing list")
            return nil
        }
        return .list(value)
    }

    private func scanString(length: String,
                            scanner: Scanner,
                            redacted: Bool,
                            withoutBuildSpecificInformation: Bool) -> String? {
        guard let value = Int(length) else {
            print("error parsing string")
            return nil
        }
        #if swift(>=5.0)
        let start = String.Index(utf16Offset: scanner.scanLocation, in: scanner.string)
        let end = String.Index(utf16Offset: scanner.scanLocation + value, in: scanner.string)
        #else
        let start = String.Index(encodedOffset: scanner.scanLocation)
        let end = String.Index(encodedOffset: scanner.scanLocation + value)
        #endif
        scanner.scanLocation += value
        var result = String(scanner.string[start..<end])
        if redacted {
            result = redactor.redactUserDir(string: result)
        }
        if withoutBuildSpecificInformation {
            result = result
                .removeProductBuildIdentifier()
                .removeHexadecimalNumbers()
        }
        return result
    }

    private func hexToInt(_ input: String) -> Double? {
        guard let beValue = UInt64(input, radix: 16) else {
            return nil
        }
        let result =  Double(bitPattern: beValue.byteSwapped)
        return result
    }
}

extension Scanner {
    var approximateLine: String {
        let endCount = string.count - scanLocation > 21 ? scanLocation + 21 : string.count - scanLocation
        #if swift(>=5.0)
        let start = String.Index(utf16Offset: scanLocation, in: self.string)
        let end = String.Index(utf16Offset: endCount, in: self.string)
        #else
        let start = String.Index(encodedOffset: scanLocation)
        let end = String.Index(encodedOffset: endCount)
        #endif
        if end <= start {
            return String(string[start..<string.endIndex])
        }
        return String(string[start..<end])
    }
}

public protocol LogRedactor {
    /// Predefined (or inferrred during redation process) user home path.
    /// Introduced for better performance.
    var userDirToRedact: String? {get set}

    /// Redacts a string by replacing sensitive username path with a template
    /// - parameter string: The string to redact
    /// - returns: Redacted text with
    func redactUserDir(string: String) -> String
}

import Foundation

public class LexRedactor: LogRedactor {
    private static let redactedTemplate = "/Users/<redacted>/"
    private lazy var userDirRegex: NSRegularExpression? = {
        do {
            return try NSRegularExpression(pattern: "/Users/([^/]+)/?")
        } catch {
            return nil
        }
    }()
    public var userDirToRedact: String?

    public init() {
    }

    public func redactUserDir(string: String) -> String {
        guard let regex = userDirRegex else {
            return string
        }
        if let userDirToRedact = userDirToRedact {
            return string.replacingOccurrences(of: userDirToRedact, with: Self.redactedTemplate)
        } else {
            guard let firstMatch = regex.firstMatch(in: string,
                                                    options: [],
                                                    range: NSRange(location: 0, length: string.count)) else {
                return string
            }
            let userDir = string.substring(firstMatch.range)
            userDirToRedact = userDir
            return string.replacingOccurrences(of: userDir, with: Self.redactedTemplate)
        }
    }
}

import Foundation

/// Methods on `String` that remove build specific information from the log.
///
/// This can be useful if we want to group logs by its content in order to indicate
/// how often particular log occurs.
extension String {
    /// Removes autogenerated build identifier in built product path.
    ///
    /// Example: "DerivedData/Product-bolnckhlbzxpxoeyfujluasoupft/Build" becomes "DerivedData/Product/Build".
    func removeProductBuildIdentifier() -> String {
        do {
            var mutableSelf = self
            let regularExpression = try NSRegularExpression(pattern: "/DerivedData/(.*)-(.*)/Build/")
            regularExpression.enumerateMatches(in: self,
                                               options: [],
                                               range: NSRange(location: 0, length: count)) { match, _, _ in
                if let match = match, match.numberOfRanges == 3 {
                    let buildIdentifier = self.substring(match.range(at: 2))
                    mutableSelf = mutableSelf.replacingOccurrences(of: "-" + buildIdentifier, with: "")
                }
            }
            return mutableSelf
        } catch {
            return self
        }
    }

    /// Removes hexadecimal numbers from the log and puts `<hexadecimal_number>` instead.
    ///
    /// Example: "NSUnderlyingError=0x7fcdc8712290" becomes "NSUnderlyingError=<hexadecimal_number>".
    func removeHexadecimalNumbers() -> String {
        do {
            var mutableSelf = self
            let regularExpression = try NSRegularExpression(pattern: "0[xX][0-9a-fA-F]+")
            regularExpression.enumerateMatches(in: self,
                                               options: [],
                                               range: NSRange(location: 0, length: count)) { match, _, _ in
                if let match = match {
                    let hexadecimalNumber = self.substring(match.range(at: 0))
                    mutableSelf = mutableSelf.replacingOccurrences(of: hexadecimalNumber, with: "<hexadecimal_number>")
                }
            }
            return mutableSelf
        } catch {
            return self
        }
    }
}
