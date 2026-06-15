//
//  BiometricAuthenticator.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import LocalAuthentication

// MARK: - Biometric Authenticator Implementation
public final class BiometricAuthenticator: BiometricAuthenticatorProtocol {
    
    public init() {}
    
    public func canEvaluatePolicy() -> Bool {
        let context = LAContext()
        var error: NSError?
        // Comprobamos si el dispositivo permite Face ID o Touch ID actualmente
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public func authenticate() async throws -> Bool {
        let context = LAContext()
        let reason = "Inicia sesión con biometría para acceder a tus personajes favoritos."
        
        AppLogger.debug("Iniciando solicitud de autenticación biométrica", category: .security)
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            AppLogger.info("Resultado de autenticación biométrica: \(success)", category: .security)
            return success
        } catch {
            AppLogger.error("Error al autenticar con biometría", category: .security, error: error)
            throw error
        }
    }
}
