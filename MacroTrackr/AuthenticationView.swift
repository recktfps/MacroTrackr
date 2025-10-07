import SwiftUI
import AuthenticationServices
import Supabase

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.doc.horizontal.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("MacroTrackr")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your nutrition, achieve your goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Authentication Form
                VStack(spacing: 20) {
                    if isSignUp {
                        TextField("Display Name", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: handleAuthentication) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text(isSignUp ? "Sign Up" : "Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && displayName.isEmpty))
                    
                    // Sign in with Apple Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(10)
                    .disabled(authManager.isLoading)
                    
                    Button(action: {
                        withAnimation {
                            isSignUp.toggle()
                        }
                    }) {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Features List
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "chart.bar.fill", title: "Track Macros", description: "Monitor calories, protein, carbs, and more")
                    FeatureRow(icon: "camera.fill", title: "Food Scanning", description: "AI-powered food recognition")
                    FeatureRow(icon: "person.2.fill", title: "Social Features", description: "Share meals with friends")
                    FeatureRow(icon: "widget.and.containers", title: "Home Widget", description: "Quick view on your home screen")
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleAuthentication() {
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password, displayName: displayName)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                          let identityToken = appleIDCredential.identityToken,
                          let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                        throw AuthenticationError.appleSignInFailed
                    }
                    
                    let authResponse = try await authManager.supabase.auth.signInWithIdToken(
                        credentials: OpenIDConnectCredentials(
                            provider: .apple,
                            idToken: identityTokenString,
                            nonce: nil
                        )
                    )
                    
                    // Create or update user profile
                    let user = authResponse.user
                    
                    let displayName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    
                    let profile = UserProfile(
                        id: user.id.uuidString,
                        displayName: displayName.isEmpty ? "Apple User" : displayName,
                        email: user.email ?? "",
                        dailyGoals: MacroGoals(),
                        isPrivate: false,
                        createdAt: Date()
                    )
                    
                    try await authManager.supabase.database
                        .from("profiles")
                        .upsert(profile)
                        .execute()
                    
                    await MainActor.run {
                        authManager.isAuthenticated = true
                        authManager.currentUser = authResponse.user
                    }
                } catch {
                    await MainActor.run {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
            }
        case .failure(let error):
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
}

enum AuthenticationError: LocalizedError {
    case appleSignInFailed
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .appleSignInFailed:
            return "Apple Sign In failed. Please try again."
        case .invalidCredentials:
            return "Invalid email or password. Please check your credentials and try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
}
