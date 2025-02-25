//
//  ZermeloAuthView.swift
//  Tasker
//
//  Created by Siddharth Sehgal on 16/02/2025.
//

import SwiftUI
import CodeScanner

struct ZermeloAuthView: View {
    @State private var school = ""
    @State private var authCode = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var isShowingScanner = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Button(action: {
                        isShowingScanner = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode.viewfinder")
                            Text("Scan QR Code")
                        }
                    }
                }
                
                Section(header: Text("Manual Entry")) {
                    TextField("Schoolnaam (bijv: school)", text: $school)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Autorisatiecode", text: $authCode)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section {
                    Button(action: authenticate) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Inloggen")
                        }
                    }
                    .disabled(school.isEmpty || authCode.isEmpty || isLoading)
                }
                
                Section {
                    Text("Je kunt je autorisatiecode vinden in het Zermelo Portal onder 'Koppel app'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Zermelo Koppelen")
            .sheet(isPresented: $isShowingScanner) {
                CodeScannerView(codeTypes: [.qr]) { result in
                    switch result {
                    case .success(let code):
                        handleScan(code: code.string)
                    case .failure(let error):
                        self.error = error
                        self.showError = true
                    }
                    isShowingScanner = false
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    private func authenticate() {
        isLoading = true
        Task {
            do {
                try await ZermeloAuthManager.shared.authenticate(
                    code: authCode,    // code first
                    school: school     // school second
                )
            } catch let zermeloError as ZermeloError {
                self.error = zermeloError
                self.showError = true
            } catch {
                self.error = error
                self.showError = true
            }
            isLoading = false
        }
    }

    private func handleScan(code: String) {
        print("Scanned QR code: \(code)")
        
        do {
            struct ZermeloQRCode: Codable {
                let institution: String
                let code: String
            }
            
            let qrData = try JSONDecoder().decode(ZermeloQRCode.self, from: code.data(using: .utf8)!)
            self.school = qrData.institution
            self.authCode = qrData.code
            print("Set school: \(school), code: \(authCode)")
            authenticate()
        } catch {
            print("QR decode error: \(error)")
            self.error = NSError(domain: "", code: 0,
                               userInfo: [NSLocalizedDescriptionKey: "Invalid QR code format: \(error.localizedDescription)"])
            self.showError = true
        }
    }
}
