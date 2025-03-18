# ZermeloSwiftIntegration

A Swift integration for **Zermelo API**, allowing users to authenticate, fetch their schedules, and manage their school timetable seamlessly. This project showcases how to interact with the Zermelo API using Swift and SwiftUI.

## Features
- **OAuth Authentication** with Zermelo API
- **Fetch and display schedules** dynamically
- **QR Code Scanning** for quick authentication
- **User session persistence** using `UserDefaults`
- Clean and modular Swift codebase

---

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Siddharth11sehgal/ZermeloSwiftIntegration.git
   cd ZermeloSwiftIntegration


---

## 🔑 Authentication

Zermelo uses OAuth for authentication. Users can:
- Enter their **school name** and **auth code** manually.
- Scan a **QR code** to automatically fetch authentication details.

#### **Example: Authenticate with Zermelo API**
```swift
Task {
    do {
        try await ZermeloAuthManager.shared.authenticate(code: "YOUR_AUTH_CODE", school: "YOUR_SCHOOL_NAME")
    } catch {
        print("Authentication failed: \(error)")
    }
}
```

---

## 📆 Fetching Schedule

Retrieve your school schedule using:
```swift
let appointments = try await ZermeloManager.shared.fetchSchedule(start: startTime, end: endTime)
```

---

## 🏗 Project Structure

- `ZermeloAuthView.swift` → Handles user authentication (manual & QR code).
- `ZermeloAuthManager.swift` → Manages OAuth token storage and authentication.
- `ZermeloManager.swift` → Fetches schedules from the API.
- `ZermeloModels.swift` → Defines data structures for Zermelo responses.

---

## 📝 Contributing
Contributions are welcome! Feel free to:
1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Commit your changes (`git commit -m "Add new feature"`).
4. Push and submit a **Pull Request**.

---

## 📜 License
This project is licensed under the MIT License.  

---

## 📬 Contact
If you have questions, reach out via GitHub or email me at **sidddevcc@gmail.com**.
```

---

### **Next Steps:**
1. **Create the README file** in your project:  
   ```bash
   touch README.md
   ```
2. **Copy-paste the above content into `README.md`**.
3. **Commit & push the file to GitHub**:  
   ```bash
   git add README.md
   git commit -m "Added README"
   git push origin main
   ```
