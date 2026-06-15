//
//  ContentView.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import SwiftUI
import Swinject

struct ContentView: View {
    // MARK: - Properties
    
    @StateObject private var listViewModel: CharacterListViewModel
    @StateObject private var favoritesViewModel: FavoritesViewModel
    
    private let detailViewModelFactory: (Character) -> CharacterDetailViewModel
    
    // MARK: - Init
    
    public init() {
        let container = DependencyRegistry.shared.container
        
        let listVM = container.resolve(CharacterListViewModel.self)!
        self._listViewModel = StateObject(wrappedValue: listVM)
        
        let favsVM = container.resolve(FavoritesViewModel.self)!
        self._favoritesViewModel = StateObject(wrappedValue: favsVM)
        
        self.detailViewModelFactory = { character in
            guard let detailVM = container.resolve(CharacterDetailViewModel.self, argument: character) else {
                fatalError("[DI] No se pudo resolver CharacterDetailViewModel para el personaje \(character.name)")
            }
            return detailVM
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        TabView {
            CharacterListView(viewModel: listViewModel, detailViewModelFactory: detailViewModelFactory)
                .tabItem {
                    Label("Personajes", systemImage: "person.3.fill")
                }
            
            FavoritesView(viewModel: favoritesViewModel, detailViewModelFactory: detailViewModelFactory)
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
