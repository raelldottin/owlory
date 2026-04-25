import Foundation

enum VoiceTranscriptionRoutingRules {
    enum Context: String, CaseIterable {
        case todayReflection
        case todayQuickNote
        case todayQuickCareer
        case trainSessionReflection
        case writeCapture
        case careerRecord
        case homeTask
    }

    enum Field: String, CaseIterable {
        case title
        case body
        case details
        case notes
        case reflection
    }

    struct Target: Equatable {
        let context: Context
        let field: Field

        init(context: Context, field: Field) {
            self.context = context
            self.field = field
        }
    }

    static let titleCharacterLimit = 100

    static func supportedFields(for context: Context) -> [Field] {
        switch context {
        case .todayReflection, .trainSessionReflection:
            return [.reflection]
        case .todayQuickNote:
            return [.body, .title]
        case .todayQuickCareer:
            return [.details, .title]
        case .writeCapture:
            return [.body]
        case .careerRecord:
            return [.details]
        case .homeTask:
            return [.notes]
        }
    }

    static func defaultField(for context: Context) -> Field {
        supportedFields(for: context)[0]
    }

    static func target(
        for context: Context,
        requestedField: Field? = nil
    ) -> Target? {
        let field = requestedField ?? defaultField(for: context)
        guard supportedFields(for: context).contains(field) else {
            return nil
        }
        return Target(context: context, field: field)
    }

    static func apply(
        _ transcription: String,
        to currentText: String,
        in context: Context,
        requestedField: Field? = nil
    ) -> String {
        guard let target = target(for: context, requestedField: requestedField) else {
            return currentText
        }
        return apply(transcription, to: currentText, target: target)
    }

    static func apply(
        _ transcription: String,
        to currentText: String,
        target: Target
    ) -> String {
        guard supportedFields(for: target.context).contains(target.field) else {
            return currentText
        }

        switch target.field {
        case .title:
            return applyingTitle(transcription, to: currentText)
        case .body, .details, .notes, .reflection:
            return appendingParagraph(transcription, to: currentText)
        }
    }

    static func applyFallback(
        _ transcription: String?,
        to currentText: String,
        in context: Context,
        requestedField: Field? = nil
    ) -> String {
        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedCurrentText.isEmpty else {
            return currentText
        }

        return apply(transcription ?? "", to: "", in: context, requestedField: requestedField)
    }
}

private extension VoiceTranscriptionRoutingRules {
    static func appendingParagraph(_ transcription: String, to currentText: String) -> String {
        let trimmedTranscription = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscription.isEmpty else {
            return currentText
        }

        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCurrentText.isEmpty else {
            return trimmedTranscription
        }

        return currentText + "\n" + trimmedTranscription
    }

    static func applyingTitle(_ transcription: String, to currentText: String) -> String {
        let trimmedTranscription = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTranscription.isEmpty else {
            return currentText
        }

        let trimmedCurrentText = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCurrentText.isEmpty else {
            return String(trimmedTranscription.prefix(titleCharacterLimit))
        }

        let remainingCharacters = titleCharacterLimit - currentText.count
        guard remainingCharacters > 1 else {
            return currentText
        }

        let appendedTranscription = String(trimmedTranscription.prefix(remainingCharacters - 1))
        guard !appendedTranscription.isEmpty else {
            return currentText
        }

        return currentText + " " + appendedTranscription
    }
}
