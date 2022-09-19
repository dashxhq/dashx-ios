import Foundation

public struct AddItemToCartModel {
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

public struct OrderItemModel {
    public let id: String
    public let quantity: DecimalScalar
    public let unitPrice: DecimalScalar
    public let subtotal: DecimalScalar
    public let discount: DecimalScalar
    public let tax: DecimalScalar
    public let total: DecimalScalar
    public let custom: [String: Any?]
    public let currencyCode: String
    
    public init(
        id: String,
        quantity: DecimalScalar,
        unitPrice: DecimalScalar,
        subtotal: DecimalScalar,
        discount: DecimalScalar,
        tax: DecimalScalar,
        total: DecimalScalar,
        custom: [String : Any?],
        currencyCode: String
    ) {
        self.id = id
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.subtotal = subtotal
        self.discount = discount
        self.tax = tax
        self.total = total
        self.custom = custom
        self.currencyCode = currencyCode
    }
}

public struct CouponRedemptionModel {
    public let coupon: CouponModel
    
    public init(coupon: CouponModel) {
        self.coupon = coupon
    }
}

public struct CouponModel {
    public let name: String
    public let identifier: String
    public let discountType: String
    public let discountAmount: DecimalScalar
    public let currencyCode: String?
    public let expiresAt: String?
    
    public init(
        name: String,
        identifier: String,
        discountType: String,
        discountAmount: DecimalScalar,
        currencyCode: String? = nil,
        expiresAt: String? = nil
    ) {
        self.name = name
        self.identifier = identifier
        self.discountType = discountType
        self.discountAmount = discountAmount
        self.currencyCode = currencyCode
        self.expiresAt = expiresAt
    }
}
