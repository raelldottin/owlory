import SwiftUI

/// App settings sheet. Currently exposes Appearance → Dusk Mode; this is the
/// hook point for future user-facing preferences.
struct SettingsView: View {
    @AppStorage(DuskModePreferenceStorage.key)
    private var duskPreferenceRaw: String = DuskModePreference.auto.rawValue

    @Environment(\.dismiss) private var dismiss

    private var duskPreferenceBinding: Binding<DuskModePreference> {
        Binding(
            get: { DuskModePreference(rawValue: duskPreferenceRaw) ?? .auto },
            set: { duskPreferenceRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker(
                        selection: duskPreferenceBinding,
                        label: Text(L("Dusk Mode"))
                    ) {
                        ForEach(DuskModePreference.allCases) { value in
                            Text(label(for: value)).tag(value)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityIdentifier("settings.appearance.duskMode")
                } header: {
                    Text(L("Appearance"))
                } footer: {
                    Text(L("Auto turns Dusk Mode on between 6 PM and 5 AM local time."))
                }
            }
            .navigationTitle(L("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("Done")) { dismiss() }
                }
            }
        }
    }

    private func label(for preference: DuskModePreference) -> LocalizedStringKey {
        switch preference {
        case .auto: return L("Auto")
        case .on: return L("On")
        case .off: return L("Off")
        }
    }
}
