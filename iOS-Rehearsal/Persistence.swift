//
//  Persistence.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import CoreData

public final class PersistenceController {
    /// Instancia única compartida del controlador en toda la aplicación (Patrón Singleton)
    public static let shared = PersistenceController()

    /// Contenedor de previsualización en memoria para el lienzo de SwiftUI (Xcode Previews)
    @MainActor
    public static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Creamos un personaje de prueba (Mock) para que las Previews muestren información real
        let mockChar = CDCharacter(context: viewContext)
        mockChar.id = 1
        mockChar.name = "Rick Sanchez"
        mockChar.status = "Alive"
        mockChar.species = "Human"
        mockChar.gender = "Male"
        mockChar.image = "https://rickandmortyapi.com/api/character/avatar/1.jpeg"
        mockChar.url = "https://rickandmortyapi.com/api/character/1"
        mockChar.originName = "Earth (C-137)"
        mockChar.locationName = "Citadel of Ricks"
        mockChar.locationUrl = "https://rickandmortyapi.com/api/location/3"
        mockChar.isFavorite = true
        mockChar.latitude = 37.7749 // San Francisco (Coordenada simulada)
        mockChar.longitude = -122.4194
         
        // Guardamos una URL de episodio de prueba (binario serializado en JSON)
        let episodeUrls = ["https://rickandmortyapi.com/api/episode/1", "https://rickandmortyapi.com/api/episode/2"]
        if let data = try? JSONEncoder().encode(episodeUrls) {
            mockChar.episodeUrlsData = data
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Error no resuelto en preview de PersistenceController: \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()

    /// El contenedor persistente de CoreData
    public let container: NSPersistentContainer

    public init(inMemory: Bool = false) {
        // Enlazamos con el archivo .xcdatamodeld
        container = NSPersistentContainer(name: "iOS_Rehearsal")
        
        if inMemory {
            // Si es en memoria (para tests o previews), redirigimos la ruta al vacío (/dev/null)
            guard let storeDescription = container.persistentStoreDescriptions.first else {
                AppLogger.error("No se encontró ninguna descripción de almacén persistente en el contenedor. La lista persistentStoreDescriptions está vacía.", category: .database)
                return
            }
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                AppLogger.error(
                    "Error crítico al cargar almacén de datos: \(error), \(error.userInfo)",
                    category: .database,
                    error: error
                )
                
                // Intentamos recuperar eliminando el almacén corrupto y recargando
                if let storeURL = storeDescription.url {
                    AppLogger.info("Intentando eliminar almacén corrupto en: \(storeURL.path)", category: .database)
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        AppLogger.info("Almacén corrupto eliminado exitosamente. Intentando recargar...", category: .database)
                        
                        // Reintentamos cargar el almacén tras eliminar el archivo corrupto
                        self.container.loadPersistentStores { (retryDescription, retryError) in
                            if let retryError = retryError as NSError? {
                                AppLogger.error(
                                    "Error fatal al recargar almacén después de eliminar archivo corrupto: \(retryError), \(retryError.userInfo)",
                                    category: .database,
                                    error: retryError
                                )
                            } else {
                                AppLogger.info("Almacén recargado exitosamente tras recuperación.", category: .database)
                            }
                        }
                    } catch {
                        AppLogger.error(
                            "No se pudo eliminar el almacén corrupto en: \(storeURL.path)",
                            category: .database,
                            error: error
                        )
                    }
                }
            }
        })
        
        // Une automáticamente los cambios del contexto en segundo plano al contexto de la vista principal
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
