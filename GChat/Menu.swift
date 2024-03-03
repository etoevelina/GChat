//
//  Menu.swift
//  GChat
//
//  Created by Эвелина Пенькова on 03.02.2024.
//

import SwiftUI


struct Menu: View {

    var body: some View {
        TabView {
            MainMessagesView()
                .tabItem {
                    Image(systemName: "message.badge")
                    Text("Messages")
                }

            SettingsView(vm: MainMessagesViewModel())
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    Menu()
}
