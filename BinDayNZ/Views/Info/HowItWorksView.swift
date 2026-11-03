import SwiftUI

/// Every boundary statement once, in one place. Other screens link here instead of repeating it.
struct HowItWorksView: View {
    var body: some View {
        List {
            Section(L("Your schedule")) {
                Text(L("Bin Day NZ shows the schedule you saved. Auckland Council's website is the source for your property's collection dates."))
                Text(L("Dates follow your saved schedule. Add any council-confirmed changes in Change schedule."))
                Text(L("An address labels your schedule. It does not set or verify your collection dates."))
                Link(L("Check dates with Auckland Council"), destination: DataService.collectionURL)
            }

            Section(L("Notifications")) {
                Text(L("Reminder times stay in New Zealand time, including when you travel."))
                Text(L("App reminders have a limited window. Open Bin Day NZ regularly to renew them; the app also schedules a renewal reminder. Settings shows the last scheduled collection date."))
                Text(L("Open the app regularly to keep upcoming reminders scheduled. Delivery also depends on your device's notification settings."))
                Text(L("A bring-in reminder and a pause while you are away are optional in Settings. A pause silences reminders only; your dates stay the same."))
            }

            Section(L("Calendar")) {
                Text(L("Collection events repeat without reopening Bin Day NZ. One-off changes update when you save your schedule. Calendar reminder events add alerts at both chosen times. To avoid duplicate alerts, turn off app notifications if you use calendar alerts."))
                Text(L("An exported file is a separate 90-day snapshot. It does not update automatically and importing it again may create duplicates."))
            }

            Section(L("Widgets")) {
                Text(L("The home screen widget shares collection dates and your chosen language with the app. It does not need your home address."))
            }

            Section(L("Coverage")) {
                Text(L("For Auckland Council kerbside collections. Shared bins, private services and island collections may have different arrangements."))
                NavigationLink(L("Privacy and Help")) { PrivacyView() }
            }
        }
        .navigationTitle(L("How Bin Day works"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
