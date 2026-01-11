import Foundation
import LocalAuthentication
import Security
import CryptoKit

// MARK: - Developer Authentication Manager
final class DeveloperAuthManager: ObservableObject {
    static let shared = DeveloperAuthManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authenticationError: String?
    @Published private(set) var lastAuthTime: Date?
    
    private let keychainService = "com.feather.developer"
    private let keychainAccount = "developerPasscode"
    private let tokenKey = "developerToken"
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    
    // Valid developer tokens (in production, these would be fetched from a secure server)
    private let validDeveloperTokens: Set<String> = [
        "FEATHER-DEV-2024-ALPHA",
        "FEATHER-DEV-2024-BETA",
        "PORTAL-INTERNAL-DEV"
    ]
    
    private init() {
        checkSessionValidity()
    }
    
    // MARK: - Session Management
    
    func checkSessionValidity() {
        guard let lastAuth = lastAuthTime else {
            isAuthenticated = false
            return
        }
        
        if Date().timeIntervalSince(lastAuth) > sessionTimeout {
            lockDeveloperMode()
        }
    }
    
    func lockDeveloperMode() {
        isAuthenticated = false
        lastAuthTime = nil
        authenticationError = nil
        AppLogManager.shared.info("Developer mode locked", category: "Security")
    }
    
    // MARK: - Passcode Management
    
    var hasPasscodeSet: Bool {
        return getStoredPasscodeHash() != nil
    }
    
    func setPasscode(_ passcode: String) -> Bool {
        guard passcode.count >= 6 else {
            authenticationError = "Passcode must be at least 6 characters"
            return false
        }
        
        let hash = hashPasscode(passcode)
        let success = saveToKeychain(hash)
        
        if success {
            AppLogManager.shared.success("Developer passcode set", category: "Security")
        } else {
            authenticationError = "Failed to save passcode"
            AppLogManager.shared.error("Failed to set developer passcode", category: "Security")
        }
        
        return success
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedHash = getStoredPasscodeHash() else {
            authenticationError = "No passcode set"
            return false
        }
        
        let inputHash = hashPasscode(passcode)
        let isValid = storedHash == inputHash
        
        if isValid {
            isAuthenticated = true
            lastAuthTime = Date()
            authenticationError = nil
            AppLogManager.shared.success("Developer passcode verified", category: "Security")
        } else {
            authenticationError = "Invalid passcode"
            AppLogManager.shared.warning("Invalid developer passcode attempt", category: "Security")
        }
        
        return isValid
    }
    
    func removePasscode() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess || status == errSecItemNotFound
        
        if success {
            lockDeveloperMode()
            AppLogManager.shared.info("Developer passcode removed", category: "Security")
        }
        
        return success
    }
    
    // MARK: - Biometric Authentication
    
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    var canUseBiometrics: Bool {
        return biometricType != .none
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometrics not available")
            return
        }
        
        let reason = "Authenticate to access Developer Mode"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.lastAuthTime = Date()
                    self?.authenticationError = nil
                    AppLogManager.shared.success("Biometric authentication successful", category: "Security")
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication failed"
                    self?.authenticationError = errorMessage
                    AppLogManager.shared.warning("Biometric authentication failed: \(errorMessage)", category: "Security")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Developer Token Validation
    
    func validateDeveloperToken(_ token: String) -> Bool {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isValid = validDeveloperTokens.contains(normalizedToken)
        
        if isValid {
            isAuthenticated = true
            lastAuthTime = Date()
            authenticationError = nil
            saveDeveloperToken(normalizedToken)
            AppLogManager.shared.success("Developer token validated", category: "Security")
        } else {
            authenticationError = "Invalid developer token"
            AppLogManager.shared.warning("Invalid developer token attempt", category: "Security")
        }
        
        return isValid
    }
    
    var hasSavedToken: Bool {
        return getSavedDeveloperToken() != nil
    }
    
    func authenticateWithSavedToken() -> Bool {
        guard let savedToken = getSavedDeveloperToken() else {
            return false
        }
        
        return validateDeveloperToken(savedToken)
    }
    
    // MARK: - Private Helpers
    
    private func hashPasscode(_ passcode: String) -> String {
        let data = Data(passcode.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func saveToKeychain(_ hash: String) -> Bool {
        let data = Data(hash.utf8)
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getStoredPasscodeHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let hash = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return hash
    }
    
    private func saveDeveloperToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func getSavedDeveloperToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func clearSavedToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        AppLogManager.shared.info("Developer token cleared", category: "Security")
    }
}
