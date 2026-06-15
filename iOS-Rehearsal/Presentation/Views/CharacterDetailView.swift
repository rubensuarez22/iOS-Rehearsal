//
//  CharacterDetailView.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import SwiftUI

// MARK: - Character Detail View
public struct CharacterDetailView: View {
    @StateObject var viewModel: CharacterDetailViewModel
    
    public init(viewModel: CharacterDetailViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header: Imagen y Botón de Favorito
                headerSection
                
                // Detalles del Personaje
                detailsSection
                
                // Botón para ir al mapa (Por ahora placeholder)
                mapButton
                
                // Listado de Episodios
                episodesSection
            }
        }
        .navigationTitle(viewModel.character.name)
        .navigationBarTitleDisplayMode(.inline)
        // Descargamos los episodios al cargar la pantalla usando API asíncrona moderna
        .task {
            await viewModel.loadEpisodes()
        }
    }
    
    // MARK: - Secciones de la Vista
    
    private var headerSection: some View {
        ZStack(alignment: .bottomTrailing) {
            CachedImage(urlString: viewModel.character.image) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
                    .clipped()
            } placeholder: {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 300)
            }
            
            // Botón de Favorito Flotante
            Button(action: {
                Task {
                    await viewModel.toggleFavorite()
                }
            }) {
                Image(systemName: viewModel.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 24))
                    .foregroundColor(viewModel.isFavorite ? .yellow : .white)
                    .padding(14)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
                    .padding()
            }
            .accessibilityIdentifier("favoriteButton")
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Información Personal")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                detailRow(label: "Estado", value: viewModel.character.status.displayName, color: statusColor(viewModel.character.status))
                Divider()
                detailRow(label: "Especie", value: viewModel.character.species)
                Divider()
                detailRow(label: "Género", value: viewModel.character.gender)
                Divider()
                detailRow(label: "Subtipo", value: viewModel.character.type.isEmpty ? "Ninguno" : viewModel.character.type)
                Divider()
                detailRow(label: "Origen", value: viewModel.character.originName)
                Divider()
                detailRow(label: "Última Ubicación", value: viewModel.character.locationName)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var mapButton: some View {
        NavigationLink(destination: CharacterMapView(character: viewModel.character)) {
            HStack {
                Image(systemName: "map.fill")
                Text("Ver en Mapa")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episodios (\(viewModel.character.episodeUrls.count))")
                .font(.title2)
                .fontWeight(.bold)
            
            switch viewModel.episodesState {
            case .loading:
                HStack {
                    Spacer()
                    ProgressView("Cargando detalles de episodios...")
                    Spacer()
                }
                .padding(.vertical)
                
            case .error(let error):
                Text("Error al cargar episodios: \(error)")
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.vertical)
                
            case .success(let episodes):
                LazyVStack(spacing: 10) {
                    ForEach(episodes) { episode in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(episode.episode) - \(episode.name)")
                                    .fontWeight(.medium)
                                Text(episode.airDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Botón interactivo para marcar como VISTO
                            Button(action: {
                                Task {
                                    await viewModel.toggleEpisodeWatched(episode: episode)
                                }
                            }) {
                                Image(systemName: episode.isWatched ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(episode.isWatched ? .green : .gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
    
    // MARK: - Helpers
    
    private func detailRow(label: String, value: String, color: Color = .primary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .font(.subheadline)
    }
    
    private func statusColor(_ status: CharacterStatus) -> Color {
        switch status {
        case .alive: return .green
        case .dead: return .red
        case .unknown: return .gray
        }
    }
}
