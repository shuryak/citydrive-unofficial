//
//  BonusButtonView.swift
//  CityDrive
//
//  Created by Иван Вдовин on 18.07.2023.
//

import SwiftUI

struct BonusButtonView: View {    
    @ObservedObject var mapVM: MapViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var openBounsBalanceInfo = false
    
    var body: some View {
        Button(
            action: {
                openBounsBalanceInfo = true
            },
            label: {
                HStack {
                    Text(mapVM.bonusBalance)
                    AsyncImage(url: URL(string: "https://api.citydrive.ru/static/img/loyalty/drivebonus_x4.png")) { image in
                        image
                            .resizable()
                            .frame(width: 20, height: 20)
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
        )
        .padding(10)
        .background(colorScheme == .dark ? Color(hex: 0x212a2e) : .white)
        .foregroundStyle(colorScheme == .dark ? .green : .black)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            mapVM.loadBonusBalance()
        }
        .sheet(isPresented: $openBounsBalanceInfo) {
            EmptyView()
        }
    }
}

#Preview {
    BonusButtonView(mapVM: MapViewModel())
}
