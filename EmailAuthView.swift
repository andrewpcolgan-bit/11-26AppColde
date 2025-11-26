//
//  EmailAuthView.swift
//  SwimSetTracker
//

import SwiftUI

struct EmailAuthView: View {
    @Environment(\.dismiss) private var dismiss

    var onDone: (String) -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Email")) {
                    TextField("name@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section(header: Text("Password")) {
                    SecureField("Choose a password", text: $password)
                }

                if let error {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button("Continue") {
                        handleContinue()
                    }
                }
            }
            .navigationTitle("Sign in / Sign up")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func handleContinue() {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.contains("@"), trimmed.contains(".") else {
            error = "Please enter a valid email address."
            return
        }

        // In a real app, call your backend / Firebase here with email + password.
        // For now we just pass the email back to Onboarding.
        onDone(trimmed)
        dismiss()
    }
}
