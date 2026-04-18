# Technovation Submission Preparation — Bin Day NZ

Congratulations on getting ready for your Technovation submission! This document outlines the key information from your project that you can use to fill out the submission checklist.

## 1. Ideation

### **Project Name**
**Bin Day NZ**

### **Description of Your Project**
*You can use this as your "Elevator Pitch" and detailed description:*

**Elevator Pitch:**
Bin Day NZ is a native iOS app designed to solve a common household frustration: forgetting which bins to put out and when. By providing timely reminders, interactive educational content locally relevant to New Zealand councils, and seamless calendar integration, we empower residents to manage their waste responsibly, reduce landfill contamination, and never miss a collection day again.

**Detailed Description:**
In New Zealand, different councils have varying schedules and rules for rubbish, recycling, and food scraps. Residents often lose track of fortnightly rotations or are unsure about what's recyclable. Bin Day NZ addresses this with:
- **Smart Reminders:** Push notifications the evening before and morning of collection.
- **Native Widgets:** At-a-glance status on the Home and Lock screens.
- **Educational Hub:** In-app videos and lists detailing "Accepted" vs. "Rejected" items for every bin type.
- **Offline Reliability:** Works fully offline with bundled data, syncing updates via CloudKit.
- **Cultural Inclusion:** Full support for Te Reo Māori alongside English.

### **Learning Journey**
*Suggested points to include:*
- **SwiftUI & SwiftData:** Learning to build a modern, high-performance interface and manage local data storage.
- **WidgetKit:** Implementing at-a-glance information for the iOS ecosystem.
- **Localization:** Integrating Te Reo Māori and understanding the importance of cultural representation in software.
- **UX Design:** Creating a flow that makes adding an address and setting reminders effortless for users of all ages.
- **Environmental Education:** Researching waste protocols to provide accurate educational content.

### **Ethics**
- **Data Privacy:** Bin Day NZ prioritizes user privacy. Home addresses and notification times are stored locally on the device or in the user's private iCloud (via CloudKit). We do not collect or sell personal data.
- **Accessibility:** The app is built with SwiftUI, ensuring it supports system-wide accessibility features like VoiceOver and Dynamic Type.
- **Cultural Responsibility:** By including Te Reo Māori, we respect the official languages of Aotearoa and ensure the app is inclusive.
- **Environmental Impact:** Our goal is to reduce waste contamination by educating users on what belongs in which bin, supporting a cleaner New Zealand.

### **2 or More Images**
Prepare screenshots of:
1. **Home Screen (Today View):** Showing the "Hero Card" with current bin status.
2. **Onboarding Flow:** Showing the address search or council selection.
3. **Info View:** Showing the "Accepted Items" list and educational videos.

---

## 2. Technical Elements

### **Coding Language**
**Swift (SwiftUI)**

### **Technical Additions**
Your project uses several advanced iOS features:
1. **WidgetKit:** Provides Small, Medium, and Lock Screen widgets for quick status updates.
2. **UserNotifications Framework:** Implements location-based and scheduled reminders.
3. **SwiftData & CloudKit:** Modern data persistence that syncs across the user's devices.
4. **Xcode String Catalogs:** Professional-grade localization for multi-language support (English & Te Reo Māori).
5. **EventKit Integration:** Allows users to sync their bin schedule directly to Apple or Google Calendars.
6. **AVKit:** Native video playback for educational waste management content.

---

## 3. Pitch & Technical Videos (Tips)

### **Pitch Video (3–4 minutes)**
- **Hook:** Start with a relatable scene—someone waking up to the sound of a garbage truck and realizing they forgot to put the bin out.
- **Problem:** Mention the confusion of different council schedules and the environmental impact of incorrect recycling.
- **Solution:** Introduce Bin Day NZ with high-energy shots of the app.
- **Market/Impact:** Explain why this is needed for all of New Zealand.
- **Call to Action:** "Let's make NZ cleaner, one bin at a time."

### **Technical Video (2 minutes)**
- **Architecture:** Mention the SwiftUI/SwiftData stack.
- **Show Code:** Briefly show `NotificationService.swift` or `BinType.swift` to demonstrate how schedules and educational content are handled.
- **Widget Demo:** Show the widget updating in real-time.
- **Language Switch:** Show the app toggling between English and Te Reo Māori to demonstrate the localization implementation.

---

## 4. Entrepreneurship
*Since you've already completed "Your Canvas", make sure to highlight:*
- **Value Proposition:** Convenience and education.
- **Customer Segments:** Homeowners, renters, and environmentally conscious residents in NZ.
- **Key Partners:** Local councils for data accuracy.
