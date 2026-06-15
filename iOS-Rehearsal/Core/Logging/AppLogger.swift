//
//  AppLogger.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation
import os

// MARK: - Log Categories
public enum LogCategory: String {
    case network = "Network"
    case database = "Database"
    case security = "Security"
    case presentation = "Presentation"
    case general = "General"
}

// MARK: - App Logger
public struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.Ruben.iOS-Rehearsal"
    
    /// Log para depuración detallada (solo visible en desarrollo)
    public static func debug(_ message: String, category: LogCategory) {
        log(message, level: .debug, category: category)
    }
    
    /// Log para mensajes informativos generales
    public static func info(_ message: String, category: LogCategory) {
        log(message, level: .info, category: category)
    }
    
    /// Log para errores críticos y excepciones
    public static func error(_ message: String, category: LogCategory, error: Error? = nil) {
        let errorSuffix = error != nil ? " | Error: \(error!.localizedDescription)" : ""
        log("\(message)\(errorSuffix)", level: .error, category: category)
    }
    
    private static func log(_ message: String, level: OSLogType, category: LogCategory) {
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        switch level {
        case .debug:
            logger.debug("[Debug] \(message, privacy: .public)")
        case .info:
            logger.info("[Info] \(message, privacy: .public)")
        case .error:
            logger.error("[Error] \(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }
    }
}
