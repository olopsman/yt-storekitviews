//
//  ContentView.swift
//  yt-storekitviews
//
//  Created by Paulo Orquillo on 22/02/2025.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @StateObject private var storeKit = StorekitManager()
    
    @State var presentSubscriptionSheet: Bool = false
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                    VStack {
                        Text("Purchased courses")
                            .font(.title)
                            .padding()
                        
                        List {
                            ForEach(storeKit.purchasedCourses, id: \.self) { product in
                                Text(product.displayName)
                            }
                        }
                        Text("Subscribe to access premium content")
                            .padding(15)
                        if !storeKit.purchasedSubscriptions.isEmpty {
                            VStack {
                                Text("Thanks for subscribing!")
                                Text("You are now subscribed to the  premium content")
                            }
                            .padding()
                        } else {
                            VStack {
                                Text("Content locked")
                                Image(systemName: "lock")
                                    .foregroundColor(.red)
                            }
                            .padding()
                        }
                        
                }
            }
            Tab("Product", systemImage: "person.crop.circle.fill") {
                ProductView(id: storeKit.productIds.first!, prefersPromotionalIcon: true)
                    .productViewStyle(.large)
            }
            
            Tab("Store", systemImage: "square.and.arrow.up") {
                
                StoreView(ids: storeKit.productIds, prefersPromotionalIcon: true)
                    .productViewStyle(.compact)
            }
            
            Tab("Subscription", systemImage: "circle.fill") {
            
                SubscriptionStoreView(groupID: storeKit.groupId)
                
                Button("Manage Subscription") {
                    presentSubscriptionSheet = true
                }
                    .manageSubscriptionsSheet(isPresented: $presentSubscriptionSheet, subscriptionGroupID: storeKit.groupId)
                
            }
            
                
            
        }
    }
}

#Preview {
    ContentView()
}
