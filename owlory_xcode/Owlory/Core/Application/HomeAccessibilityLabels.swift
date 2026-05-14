import Foundation

enum HomeAccessibilityLabels {
    static func taskEdit(title: String) -> String {
        format("home.task.accessibility.edit", title)
    }

    static func taskSkip(title: String) -> String {
        format("home.task.accessibility.skip", title)
    }

    static func taskMarkComplete(title: String) -> String {
        format("home.task.accessibility.markComplete", title)
    }

    static func taskMarkIncomplete(title: String) -> String {
        format("home.task.accessibility.markIncomplete", title)
    }

    static func taskRestore(title: String) -> String {
        format("home.task.accessibility.restore", title)
    }

    static func protocolStepComplete(title: String) -> String {
        format("home.protocol.step.accessibility.complete", title)
    }

    static func protocolStepSkip(title: String) -> String {
        format("home.protocol.step.accessibility.skip", title)
    }

    private static func format(_ key: String, _ argument: String) -> String {
        String.localizedStringWithFormat(
            NSLocalizedString(key, comment: "Home action accessibility label with interpolated item title."),
            argument
        )
    }
}
