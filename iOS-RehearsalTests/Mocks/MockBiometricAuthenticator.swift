//
//  MockBiometricAuthenticator.swift
//  iOS-RehearsalTests
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
@testable import iOS_Rehearsal

/// Un Proxy de pruebas que implementa `BiometricAuthenticatorProtocol` para simular
/// la presencia de hardware de autenticación biométrica y la respuesta del usuario (éxito/error).
public final class MockBiometricAuthenticator: BiometricAuthenticatorProtocol, @unchecked Sendable {
    public var shouldCanEvaluatePolicy = true
    public var shouldAuthenticateSuccessfully = true
    public var errorToThrow: Error?
    
    public var canEvaluatePolicyCalledCount = 0
    public var authenticateCalledCount = 0
    
    public init() {}
    
    public func canEvaluatePolicy() -> Bool {
        canEvaluatePolicyCalledCount += 1
        return shouldCanEvaluatePolicy
    }
    
    public func authenticate() async throws -> Bool {
        authenticateCalledCount += 1
        if let error = errorToThrow {
            throw error
        }
        return shouldAuthenticateSuccessfully
    }
}
