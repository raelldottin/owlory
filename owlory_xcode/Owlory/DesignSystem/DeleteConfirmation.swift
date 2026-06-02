import SwiftUI

extension View {
    /// Gate a destructive delete behind a confirmation dialog.
    ///
    /// Bind `item` to optional state that names the row pending deletion. From a
    /// swipe action, context menu, or `onDelete`, set that state instead of
    /// deleting immediately — this presents a confirmation dialog and only runs
    /// `perform` after the user confirms. Confirming or cancelling clears the
    /// binding.
    ///
    /// Host the modifier on the enclosing `List`/section rather than the row, so
    /// the dialog stays presented while the confirmed row is removed. The
    /// confirm and cancel buttons reuse the shared `Delete`/`Cancel` keys; pass a
    /// localized `title` (and optional `message`) describing what is removed.
    func deleteConfirmation<Item: Equatable>(
        _ title: LocalizedStringKey,
        item: Binding<Item?>,
        confirmLabel: LocalizedStringKey = L("Delete"),
        message: LocalizedStringKey? = nil,
        perform: @escaping (Item) -> Void
    ) -> some View {
        confirmationDialog(
            title,
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented { item.wrappedValue = nil }
                }
            ),
            titleVisibility: .visible
        ) {
            Button(confirmLabel, role: .destructive) {
                if let target = item.wrappedValue {
                    perform(target)
                }
                item.wrappedValue = nil
            }
            Button(L("Cancel"), role: .cancel) {
                item.wrappedValue = nil
            }
        } message: {
            if let message {
                Text(message)
            }
        }
    }
}
