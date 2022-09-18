import Foundation
import GraphQL
import SwiftGraphQL

extension IdentifyAccountModel {
    static func input(
        uid: String?,
        anonymousUid: String?,
        email: String?,
        phone: String?,
        name: String?,
        firstName: String?,
        lastName: String?,
        scope: String? = nil,
        systemContext: InputObjects.SystemContextInput? = nil
    ) -> InputObjects.IdentifyAccountInput {
        let uid = OptionalArgument(present: uid)
        let anonymousUid = OptionalArgument(present: anonymousUid)
        let email = OptionalArgument(present: email)
        let phone = OptionalArgument(present: phone)
        let name = OptionalArgument(present: name)
        let firstName = OptionalArgument(present: firstName)
        let lastName = OptionalArgument(present: lastName)
        let scope = OptionalArgument(present: scope)
        let systemContext = OptionalArgument(present: systemContext)
        
        return InputObjects.IdentifyAccountInput(
            uid: uid,
            anonymousUid: anonymousUid,
            email: email,
            phone: phone,
            name: name,
            firstName: firstName,
            lastName: lastName,
            scope: scope,
            systemContext: systemContext
        )
    }
    
    static let selection = Selection.Account<IdentifyAccountModel> {
        let id = try $0.id()
        
        return IdentifyAccountModel(id: id)
    }
    
    static func mutation(input: InputObjects.IdentifyAccountInput) -> Selection<IdentifyAccountModel, Objects.Mutation> {
        return Selection.Mutation<IdentifyAccountModel> {
            try $0.identifyAccount(input: input, selection: selection)
        }
    }
}
