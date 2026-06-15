//
//  iOS_RehearsalUITests.swift
//  iOS-RehearsalUITests
//
//  Created by Rubén Suárez on 14/06/26.
//

import XCTest

final class iOS_RehearsalUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Código de limpieza
    }

    @MainActor
    func testNavigationAndDetailFlow() throws {
        let app = XCUIApplication()
        // Agregamos el argumento de lanzamiento para inyectar FakeBiometricAuthenticator
        app.launchArguments.append("--uitesting")
        app.launch()

        // 1. Verificar que estamos en la pantalla principal y que el listado de personajes existe
        let navigationTitle = app.navigationBars["Personajes"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: 5.0), "La barra de navegación principal 'Personajes' debería existir.")
        
        // 2. Localizar e interactuar con la barra de búsqueda nativa de SwiftUI
        let searchField = app.searchFields["Buscar personaje..."]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5.0), "El campo de búsqueda debería ser visible.")
        searchField.tap()
        searchField.typeText("Rick")
        
        // 3. Seleccionar la primera celda que coincida con la búsqueda (por ejemplo, "Rick Sanchez")
        let firstCell = app.cells.firstMatch
        XCTAssertTrue(firstCell.waitForExistence(timeout: 5.0), "Debería cargarse al menos un personaje que coincida con la búsqueda.")
        firstCell.tap()
        
        // 4. Verificar la transición al detalle (el título de la barra de navegación cambia al nombre del personaje)
        let detailNavigationTitle = app.navigationBars["Rick Sanchez"]
        XCTAssertTrue(detailNavigationTitle.waitForExistence(timeout: 5.0), "Debería haber navegado al detalle de Rick Sanchez.")
        
        // 5. Marcar al personaje como favorito pulsando el botón flotante con identificador de accesibilidad
        let favoriteButton = app.buttons["favoriteButton"]
        XCTAssertTrue(favoriteButton.exists, "El botón de favorito debería existir en la vista de detalle.")
        favoriteButton.tap()
        
        // 6. Volver a la pantalla anterior (Lista principal)
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists, "El botón de retroceso debería estar visible.")
        backButton.tap()
        
        // 7. Navegar a la pestaña de Favoritos en la TabBar
        let favoritesTab = app.tabBars.buttons["Favoritos"]
        XCTAssertTrue(favoritesTab.exists, "La pestaña 'Favoritos' debería estar en la barra inferior.")
        favoritesTab.tap()
        
        // 8. Verificar que la pantalla se desbloquea instantáneamente (gracias a FakeBiometricAuthenticator)
        // y muestra a "Rick Sanchez" en la lista de favoritos de CoreData
        let favoriteCellText = app.cells.staticTexts["Rick Sanchez"]
        XCTAssertTrue(favoriteCellText.waitForExistence(timeout: 5.0), "Rick Sanchez debería mostrarse en la lista de favoritos tras desbloquear.")
    }
}
