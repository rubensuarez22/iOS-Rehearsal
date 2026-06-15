//
//  CharacterStatus+Display.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import Foundation

// Extensión de Presentación: los textos de UI no pertenecen a la capa de Dominio
extension CharacterStatus {
    public var displayName: String {
        switch self {
        case .alive: return "Vivo"
        case .dead: return "Muerto"
        case .unknown: return "Desconocido"
        }
    }
}
