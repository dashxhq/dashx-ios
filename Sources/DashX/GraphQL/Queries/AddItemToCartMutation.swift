import Foundation
import GraphQL
import SwiftGraphQL

extension AddItemToCartModel {
    static func input(
        uid: String? = nil,
        anonymousUid: String? = nil,
        itemId: String,
        pricingId: String,
        quantity: String,
        reset: Bool,
        custom: NSDictionary? = nil
    ) -> InputObjects.AddItemToCartInput {
        let uid = OptionalArgument(present: uid)
        let anonymousUid = OptionalArgument(present: anonymousUid)
        let customAsAnyCodable = AnyCodable(custom)
        let custom = OptionalArgument(present: customAsAnyCodable)
        
        return InputObjects.AddItemToCartInput(
            accountUid: uid,
            accountAnonymousUid: anonymousUid,
            itemId: itemId,
            pricingId: pricingId,
            quantity: quantity,
            reset: reset,
            custom: custom
        )
    }
    
    static let selection = Selection.Order<AddItemToCartModel> {
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
        
        return AddItemToCartModel(
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
    
    static func mutation(input: InputObjects.AddItemToCartInput) -> Selection<AddItemToCartModel, Objects.Mutation> {
        return Selection.Mutation<AddItemToCartModel> {
            try $0.addItemToCart(input: input, selection: selection)
        }
    }
}

extension OrderItemModel {
    static let selection = Selection.OrderItem<OrderItemModel> {
        let id = try $0.id()
        let quantity = try $0.quantity()
        let unitPrice = try $0.unitPrice()
        let subtotal = try $0.subtotal()
        let discount = try $0.discount()
        let tax = try $0.tax()
        let total = try $0.total()
        let custom = try $0.custom().value as? [String: Any] ?? [:]
        let currencyCode = try $0.currencyCode()
        
        return OrderItemModel(
            id: id,
            quantity: quantity,
            unitPrice: unitPrice,
            subtotal: subtotal,
            discount: discount,
            tax: tax,
            total: total,
            custom: custom,
            currencyCode: currencyCode
        )
    }
}

extension CouponRedemptionModel {
    static let selection = Selection.CouponRedemption<CouponRedemptionModel> {
        let coupon = try $0.coupon(selection: CouponModel.selection)
        
        return CouponRedemptionModel(coupon: coupon)
    }
}

extension CouponModel {
    static let selection = Selection.Coupon<CouponModel> {
        let name = try $0.name()
        let identifier = try $0.identifier()
        let discountType = try $0.discountType()
        let discountAmount = try $0.discountAmount()
        let currencyCode = try $0.currencyCode()
        let expiresAt = try $0.expiresAt()
        
        return CouponModel(
            name: name,
            identifier: identifier,
            discountType: discountType.rawValue,
            discountAmount: discountAmount,
            currencyCode: currencyCode,
            expiresAt: expiresAt
        )
    }
}
