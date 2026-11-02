# Bin Day NZ: App Store listing, version 1.2

Draft for review, 1 November 2026. English only; localised copy needs fluent review. Nothing here has been published.

## App name

Bin Day NZ

## Subtitle

Never miss recycling week

## Promotional text

Rubbish, recycling and food scraps, sorted for your Auckland household. Set each bin once, then let a reminder, a widget or your calendar tell you what goes out tonight.

## Description

Never wonder whether it's recycling week again. Bin Day NZ shows what goes out next, reminds you the evening before and the morning of, and keeps rubbish, recycling and food scraps on their own weekly or fortnightly schedules, so the whole household is on the same page.

- Notifications: an evening-before and a morning-of reminder for each collection.
- Widgets: the next collection on your home screen or lock screen.
- Calendar: optional recurring events in Apple Calendar, or a 90-day .ics export.
- Holidays: move or skip a single collection without changing the regular schedule.
- Sorting guide: what goes in which bin in Auckland, with links to the official sources.
- Five languages: English, Te Reo Māori, Simplified Chinese, Hindi and Korean.

Good to know: you set each bin's schedule yourself after checking Auckland Council's website, which remains the source for your dates; Bin Day NZ doesn't fetch them for you. It's made for Auckland Council kerbside collections, so shared bins, private services and island collections may differ. Reminders are scheduled in batches and renew whenever you open the app, so open it now and then. Adding your address is optional and only labels your schedule. There's no account, no ads and no tracking, and everything stays on your device.

## Keywords

rubbish,recycling,food scraps,collection,reminder,widget,Auckland,council,kerbside,calendar,waste

## What's New in 1.2

You can now set each bin separately, and move or skip a single collection when a holiday shifts the week. Reminders, widgets and calendar events follow your changes.

Please review your saved dates after updating, so your reminders match your bins.

## Suggested reply to JoelRT32's June review

Thanks for the suggestion, Joel, and for your patience. Version 1.2 lets you set the schedule for each bin separately (weekly or fortnightly), and you can now move or skip a single collection when a holiday changes the day. If you try it, we'd love to hear how it works for your street.

## App Store Connect actions (by hand)

- [ ] Re-answer the age-rating questionnaire. It is currently 16+ because of "Unrestricted Web Access", but the only web content is one YouTube embed behind an explicit Load video button, so 4+ is likely correct.
- [ ] Decide whether to keep "Mac (Designed for iPad)" and visionOS availability. Neither has been tested.
- [ ] Replace screenshots with captures of the 1.2 UI. Staged under `docs/store-assets/1.2/` (see below); upload once 1.2 leaves review.
- [ ] Set the Support URL and the Privacy Policy URL.
- [ ] Remove the 1.1 wording about real-time council fetching and address-based zone lookup; nothing above promises it.
- [ ] Post the review reply only after 1.2 is live.

## Screenshots (captured 2 November 2026)

Final PNGs live in `docs/store-assets/1.2/`, captured on Xcode 26.3 simulators in light mode with the status bar overridden to 9:41 and full battery. The sample schedule is rubbish weekly on Tuesday, recycling fortnightly from 3 November and food scraps fortnightly from 10 November, with reminders allowed, so Today shows "Reminders on".

| Order | File | Screen |
| --- | --- | --- |
| 1 | `01-today.png` | Today: "Tomorrow" hero, reminder status, upcoming list |
| 2 | `02-setup-complete.png` | Setup-success screen with widget and share cards |
| 3 | `03-schedule-editor.png` | Guided per-bin editor, recycling and food scraps on alternate weeks |
| 4 | `04-schedule.png` | Schedule tab, November calendar |
| 5 | `05-home-widget.png` | Home Screen with the medium widget |
| 6 | `06-recycling-guide.png` | Recycling bin guide |

Sets:

- `iphone-6.9/` 1320×2868 from iPhone 17 Pro Max, for display type `IPHONE_67` (Apple's 6.9-inch slot).
- `iphone-6.5/` 1284×2778, the same images downscaled with sips, to replace the legacy `IPHONE_65` set rather than leave the March 2026 captures on 6.5-inch devices.
- `ipad-13/` 2064×2752 from iPad Pro 13-inch (M5), for display type `IPAD_PRO_3GEN_129`.

Capture is reproducible: uninstall the app from the simulator, run `xcrun simctl status_bar <udid> override --time 9:41 --batteryState discharging --batteryLevel 100 --wifiBars 3 --cellularBars 4`, then run the `StoreScreenshotUITests` UI test and export attachments with `xcrun xcresulttool export attachments`. The widget frame is a `simctl io screenshot` after adding the medium widget by hand; simctl writes RGBA, which App Store Connect rejects, so flatten it to RGB (Pillow `Image.open(p).convert("RGB").save(p)`) before uploading. `asc screenshots validate` does not catch this; `asc screenshots upload --dry-run` does.

Upload, once the version is editable (1.2 was still WAITING_FOR_REVIEW on 2 November, and changing screenshots then would need a developer reject):

```
asc screenshots upload --app 6761326182 --version 1.2 --locale en-AU --path docs/store-assets/1.2/iphone-6.9 --device-type IPHONE_67 --replace --confirm
asc screenshots upload --app 6761326182 --version 1.2 --locale en-AU --path docs/store-assets/1.2/iphone-6.5 --device-type IPHONE_65 --replace --confirm
asc screenshots upload --app 6761326182 --version 1.2 --locale en-AU --path docs/store-assets/1.2/ipad-13 --device-type IPAD_PRO_3GEN_129 --replace --confirm
asc screenshots list --app 6761326182 --version 1.2 --locale en-AU
```

If 1.2 is already live and locked by then, create the next version first and upload there.
