import Foundation
import GraphQL
import SwiftGraphQL

extension FetchCartModel {
    static func input(
        uid: String? = nil,
        anonymousUid: String? = nil,
        orderId: String? = nil
    ) -> InputObjects.FetchCartInput {
        let uid = OptionalArgument(present: uid)
        let anonymousUid = OptionalArgument(present: anonymousUid)
        let orderId = OptionalArgument(present: orderId)
        
        return InputObjects.FetchCartInput(
            accountUid: uid,
            accountAnonymousUid: anonymousUid,
            orderId: orderId
        )
    }
    
    static let selection = Selection.Order<FetchCartModel> {
        let id = try $0.id()
        let status = try $0.status()
        let subtotal = try $0.subtotal()
        let discount = try $0.discount()
        let tax = try $0.tax()
        let total = try $0.total()
        let gatewayMeta = try $0.gatewayMeta()?.value as? [String: Any?] ?? [:]
        let currencyCode = try $0.currencyCode()
        let orderItems = try $0.orderItems(selection: .list(OrderItemModel.selection))
        let couponRedemptions = try $0.couponRedemptions(selection: .list(CouponRedemptionModel.selection))
        
        return FetchCartModel(
            id: id,
            status: status.rawValue,
            subtotal: subtotal,
            discount: discount,
            tax: tax,
            total: total,
            gatewayMeta: gatewayMeta,
            currencyCode: currencyCode,
            orderItems: orderItems,
            couponRedemptions: couponRedemptions
        )
    }
    
    static func query(input: InputObjects.FetchCartInput) -> Selection<FetchCartModel, Objects.Query> {
        return Selection.Query<FetchCartModel> {
            try $0.fetchCart(input: input, selection: selection)
        }
    }
}
