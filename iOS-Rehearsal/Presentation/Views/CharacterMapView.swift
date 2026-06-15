//
//  CharacterMapView.swift
//  iOS-Rehearsal
//
//  Created by Rubén Suárez on 14/06/26.
//

import SwiftUI
import MapKit

// MARK: - Character Map View
public struct CharacterMapView: View {
    let characters: [Character]
    
    // Estado de la cámara y posicionamiento del mapa
    @State private var position: MapCameraPosition
    
    // Inicializador para múltiples personajes
    public init(characters: [Character]) {
        self.characters = characters
        
        // Calculamos la posición inicial:
        // Si hay personajes, centramos en el primero. De lo contrario, en el CERN (Ginebra)
        if let first = characters.first {
            let coordinate = CLLocationCoordinate2D(latitude: first.latitude, longitude: first.longitude)
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            _position = State(initialValue: .region(region))
        } else {
            let cernCoordinate = CLLocationCoordinate2D(latitude: 46.2044, longitude: 6.1432)
            let region = MKCoordinateRegion(
                center: cernCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            _position = State(initialValue: .region(region))
        }
    }
    
    // Inicializador conveniente para un solo personaje
    public init(character: Character) {
        self.init(characters: [character])
    }
    
    public var body: some View {
        Map(position: $position) {
            ForEach(characters) { character in
                // Añadimos una anotación estilizada con la foto del personaje sobre su pin
                Annotation(
                    character.name,
                    coordinate: CLLocationCoordinate2D(latitude: character.latitude, longitude: character.longitude)
                ) {
                    VStack(spacing: 4) {
                        CachedImage(urlString: character.image) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(.blue)
                                .background(Color.white)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 4)
                        }
                        
                        Text(character.name)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(6)
                            .shadow(radius: 2)
                    }
                }
            }
        }
        .mapControls {
            // Controles de brújula y escala nativos
            MapCompass()
            MapScaleView()
        }
        .navigationTitle(characters.count == 1 ? characters.first!.name : "Ubicación")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CharacterMapView(character: Character(
        id: 1,
        name: "Rick Sanchez",
        status: .alive,
        species: "Human",
        type: "",
        gender: "Male",
        image: "https://rickandmortyapi.com/api/character/avatar/1.jpeg",
        url: "https://rickandmortyapi.com/api/character/1",
        originName: "Earth",
        locationName: "CERN",
        locationUrl: "",
        episodeUrls: [],
        latitude: 46.2044,
        longitude: 6.1432
    ))
}
