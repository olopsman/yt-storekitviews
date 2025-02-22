//
//  StorekitManager.swift
//  yt-storekitviews
//
//  Created by Paulo Orquillo on 22/02/2025.
//

import StoreKit

class StorekitManager: ObservableObject {
    var productIds = ["unrealengine", "swift"]
    var subscriptionIds = ["premium", "basic"]
    var groupId = "9ECCAA9A"
    @Published private(set) var courses: [Product] = []
    @Published private(set) var purchasedCourses: [Product] = []
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            
            await updateCustomerProductStatus()
        }
    }
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //iterate for incoming transactions
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await self.updateCustomerProductStatus()
                    
                    await transaction.finish()
                    
                }catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    @MainActor
    func requestProducts() async {
        do {
            let storeProducts = try await Product.products(for: productIds + subscriptionIds)
            
            for product in storeProducts {
                switch product.type {
                case .nonConsumable:
                    courses.append(product)
                case .autoRenewable:
                    subscriptions.append(product)
                default:
                    print("unknown product")
                }
            }
        } catch {
            print("failed product request")
        }
    }
    
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedCourses: [Product] = []
        var purchasedSubscriptions: [Product] = []
        
        //iterate to the all the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                //check producttype
                switch transaction.productType {
                case .nonConsumable:
                    if let course = courses.first(where: { $0.id == transaction.productID }) {
                        purchasedCourses.append(course)
                    }
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: { $0.id == transaction.productID }) {
                        purchasedSubscriptions.append(subscription)
                    }
                default:
                    break
                }
                
            } catch {
                print()
            }
        }
        
        self.purchasedCourses = purchasedCourses
        self.purchasedSubscriptions = purchasedSubscriptions
      
    }
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        // Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            // StoreKit parses the JWS, but it fails verification.
            throw StoreError.failedVerification
        case .verified(let safe):
            // The result is verified. Return the unwrapped value.
            return safe
        }
    }
    
    public enum StoreError: Error {
        case failedVerification
    }
    
}
