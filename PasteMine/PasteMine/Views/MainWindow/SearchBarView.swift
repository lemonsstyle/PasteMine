//
//  SearchBarView.swift
//  PasteMine
//
//  Created by lagrange on 2025/11/22.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchText: String
    @State private var isHovered = false

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background {
            if #available(macOS 14, *) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(isHovered ? 0.12 : 0.06),
                            radius: isHovered ? 4 : 2,
                            y: isHovered ? 2 : 1)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            }
        }
        .padding(.horizontal)
        .padding(.top)
        .onHover { hovering in
            withAnimation(.smooth(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

