import Foundation

public struct FetchCartModel {
    public let id: String
    public let status: String
    public let subtotal: DecimalScalar
    public let discount: DecimalScalar
    public let tax: DecimalScalar
    public let total: DecimalScalar
    public let gatewayMeta: [String: Any?]
    public let currencyCode: String
    public let orderItems: [OrderItemModel]
    public let couponRedemptions: [CouponRedemptionModel]
    
    public init(
        id: String,
        status: String,
        subtotal: DecimalScalar,
        discount: DecimalScalar,
        tax: DecimalScalar,
        total: DecimalScalar,
        gatewayMeta: [String : Any?],
        currencyCode: String,
        orderItems: [OrderItemModel],
        couponRedemptions: [CouponRedemptionModel]
    ) {
        self.id = id
        self.status = status
        self.subtotal = subtotal
        self.discount = discount
        self.tax = tax
        self.total = total
        self.gatewayMeta = gatewayMeta
        self.currencyCode = currencyCode
        self.orderItems = orderItems
        self.couponRedemptions = couponRedemptions
    }
}
