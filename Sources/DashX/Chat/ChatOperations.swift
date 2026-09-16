// @_implementationOnly — see `DashXClient.swift` for rationale.
@_implementationOnly import Apollo
#if canImport(ApolloAPI)
@_implementationOnly import ApolloAPI
#endif
import Foundation

// Raw chat operations; each requires an identity token. `chat(chatIdentityId:)` is the managed surface.

public extension DashXClient {
    /// `content` is `{"text": "<1–4096 characters>"}` and `clientMessageId` 1–128 characters of
    /// `[A-Za-z0-9._-]`. Re-sending a committed `clientMessageId` returns the existing message.
    func sendInAppChatMessage(
        conversationId: String,
        identityId: String,
        content: [String: Any],
        clientMessageId: String,
        completion: @escaping (Result<DashXChatMessage, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let mutation = DashXGql.SendInAppChatMessageMutation(
            conversationId: conversationId,
            identityId: identityId,
            content: Self.toJSONScalar(content),
            clientMessageId: clientMessageId
        )
        performChat(mutation, completion: sessionBound(completion)) { data in
            DashXChatMessage(fragment: data.sendInAppChatMessage.fragments.chatMessageFragment)
        }
    }

    /// `afterMessageId` selects rows strictly after that message; mutually exclusive with `page`.
    func fetchInAppChatMessages(
        conversationId: String,
        limit: Int? = nil,
        page: Int? = nil,
        afterMessageId: String? = nil,
        completion: @escaping (Result<[DashXChatMessage], Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.FetchInAppChatMessagesQuery(
            conversationId: conversationId,
            limit: limit.map { .some($0) } ?? .null,
            page: page.map { .some($0) } ?? .null,
            afterMessageId: afterMessageId.map { .some($0) } ?? .null
        )
        fetchChat(query, completion: sessionBound(completion)) { data in
            data.fetchInAppChatMessages.map { DashXChatMessage(fragment: $0.fragments.chatMessageFragment) }
        }
    }

    func summarizeInAppChatMessages(
        conversationId: String,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.SummarizeInAppChatMessagesQuery(conversationId: conversationId)
        fetchChat(query, completion: sessionBound(completion)) { data in
            data.summarizeInAppChatMessages.count
        }
    }

    /// `properties` is an equality filter; the page total comes from `summarizeInAppChatConversations`.
    func fetchInAppChatConversations(
        identityId: String,
        limit: Int? = nil,
        page: Int? = nil,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil,
        completion: @escaping (Result<[DashXChatConversationSummary], Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.FetchInAppChatConversationsQuery(
            identityId: identityId,
            limit: limit.map { .some($0) } ?? .null,
            page: page.map { .some($0) } ?? .null,
            statuses: statuses.map { .some($0) } ?? .null,
            properties: properties.map { .some(Self.toJSONScalar($0)) } ?? .null
        )
        fetchChat(query, completion: sessionBound(completion)) { data in
            data.fetchInAppChatConversations.map {
                DashXChatConversationSummary(fragment: $0.fragments.chatConversationSummaryFragment)
            }
        }
    }

    func fetchInAppChatConversation(
        identityId: String,
        conversationId: String,
        completion: @escaping (Result<DashXChatConversationSummary, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.FetchInAppChatConversationQuery(identityId: identityId, conversationId: conversationId)
        fetchChat(query, completion: sessionBound(completion)) { data in
            DashXChatConversationSummary(fragment: data.fetchInAppChatConversation.fragments.chatConversationSummaryFragment)
        }
    }

    /// Total matching the same filters as `fetchInAppChatConversations`.
    func summarizeInAppChatConversations(
        identityId: String,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.SummarizeInAppChatConversationsQuery(
            identityId: identityId,
            statuses: statuses.map { .some($0) } ?? .null,
            properties: properties.map { .some(Self.toJSONScalar($0)) } ?? .null
        )
        fetchChat(query, completion: sessionBound(completion)) { data in
            data.summarizeInAppChatConversations.count
        }
    }

    /// Total unread across the visitor's conversations.
    func summarizeInAppChatUnread(
        identityId: String,
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let query = DashXGql.SummarizeInAppChatUnreadQuery(identityId: identityId)
        fetchChat(query, completion: sessionBound(completion)) { data in
            data.summarizeInAppChatUnread.count
        }
    }

    /// `lastMessageId` must be a server message id, never a local optimistic one. Idempotent; the
    /// read position only moves forward.
    func markInAppChatConversationRead(
        identityId: String,
        conversationId: String,
        lastMessageId: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let mutation = DashXGql.MarkInAppChatConversationReadMutation(
            identityId: identityId,
            conversationId: conversationId,
            lastMessageId: lastMessageId
        )
        performChat(mutation, completion: sessionBound(completion)) { data in
            data.markInAppChatConversationRead.success
        }
    }

    /// Visitor-initiated end of an active conversation; apply the returned status as-is. A later
    /// message reopens it.
    func resolveInAppChatConversation(
        identityId: String,
        conversationId: String,
        completion: @escaping (Result<DashXChatConversationSummary, Error>) -> Void
    ) {
        guard requireIdentityToken(completion) else { return }
        let mutation = DashXGql.ResolveInAppChatConversationMutation(identityId: identityId, conversationId: conversationId)
        performChat(mutation, completion: sessionBound(completion)) { data in
            DashXChatConversationSummary(fragment: data.resolveInAppChatConversation.fragments.chatConversationSummaryFragment)
        }
    }
}

// MARK: - async/await overloads

public extension DashXClient {
    func sendInAppChatMessage(
        conversationId: String,
        identityId: String,
        content: [String: Any],
        clientMessageId: String
    ) async throws -> DashXChatMessage {
        try await withCheckedThrowingContinuation { continuation in
            sendInAppChatMessage(conversationId: conversationId, identityId: identityId, content: content, clientMessageId: clientMessageId) {
                continuation.resume(with: $0)
            }
        }
    }

    func fetchInAppChatMessages(
        conversationId: String,
        limit: Int? = nil,
        page: Int? = nil,
        afterMessageId: String? = nil
    ) async throws -> [DashXChatMessage] {
        try await withCheckedThrowingContinuation { continuation in
            fetchInAppChatMessages(conversationId: conversationId, limit: limit, page: page, afterMessageId: afterMessageId) {
                continuation.resume(with: $0)
            }
        }
    }

    func summarizeInAppChatMessages(conversationId: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            summarizeInAppChatMessages(conversationId: conversationId) { continuation.resume(with: $0) }
        }
    }

    func fetchInAppChatConversations(
        identityId: String,
        limit: Int? = nil,
        page: Int? = nil,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil
    ) async throws -> [DashXChatConversationSummary] {
        try await withCheckedThrowingContinuation { continuation in
            fetchInAppChatConversations(identityId: identityId, limit: limit, page: page, statuses: statuses, properties: properties) {
                continuation.resume(with: $0)
            }
        }
    }

    func fetchInAppChatConversation(identityId: String, conversationId: String) async throws -> DashXChatConversationSummary {
        try await withCheckedThrowingContinuation { continuation in
            fetchInAppChatConversation(identityId: identityId, conversationId: conversationId) { continuation.resume(with: $0) }
        }
    }

    func summarizeInAppChatConversations(
        identityId: String,
        statuses: [String]? = nil,
        properties: [String: Any]? = nil
    ) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            summarizeInAppChatConversations(identityId: identityId, statuses: statuses, properties: properties) {
                continuation.resume(with: $0)
            }
        }
    }

    func summarizeInAppChatUnread(identityId: String) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            summarizeInAppChatUnread(identityId: identityId) { continuation.resume(with: $0) }
        }
    }

    func markInAppChatConversationRead(identityId: String, conversationId: String, lastMessageId: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            markInAppChatConversationRead(identityId: identityId, conversationId: conversationId, lastMessageId: lastMessageId) {
                continuation.resume(with: $0)
            }
        }
    }

    func resolveInAppChatConversation(identityId: String, conversationId: String) async throws -> DashXChatConversationSummary {
        try await withCheckedThrowingContinuation { continuation in
            resolveInAppChatConversation(identityId: identityId, conversationId: conversationId) { continuation.resume(with: $0) }
        }
    }
}

// MARK: - Internals

extension DashXClient {
    /// Gates a completion on the session generation it began under: a request begun as user A must
    /// not deliver into user B's UI. Same-identity token refreshes leave the generation unchanged.
    func sessionBound<T>(_ completion: @escaping (Result<T, Error>) -> Void) -> (Result<T, Error>) -> Void {
        let generation = currentSessionGeneration
        return { result in
            if DashXClient.instance.currentSessionGeneration != generation {
                completion(.failure(DashXClientError.sessionEnded))
            } else {
                completion(result)
            }
        }
    }

    private func requireIdentityToken<T>(_ completion: @escaping (Result<T, Error>) -> Void) -> Bool {
        if hasIdentityToken { return true }
        DispatchQueue.main.async { completion(.failure(DashXClientError.notIdentified)) }
        return false
    }

    private func performChat<Mutation: GraphQLMutation, Value>(
        _ mutation: Mutation,
        completion: @escaping (Result<Value, Error>) -> Void,
        map: @escaping (Mutation.Data) -> Value
    ) {
        Network.shared.apollo.perform(mutation: mutation) { result in
            completion(Self.mapChatResult(result, map: map))
        }
    }

    private func fetchChat<Query: GraphQLQuery, Value>(
        _ query: Query,
        completion: @escaping (Result<Value, Error>) -> Void,
        map: @escaping (Query.Data) -> Value
    ) {
        Network.shared.apollo.fetch(query: query, cachePolicy: .fetchIgnoringCacheData) { result in
            completion(Self.mapChatResult(result, map: map))
        }
    }

    private static func mapChatResult<Data, Value>(
        _ result: Result<GraphQLResult<Data>, Error>,
        map: (Data) -> Value
    ) -> Result<Value, Error> {
        switch result {
        case .success(let graphQLResult):
            if let errors = graphQLResult.errors, !errors.isEmpty {
                DashXLog.e(tag: "DashXChat", "GraphQL errors: \(errors)")
                return .failure(DashXClientError.fromGraphQL(errors))
            }
            guard let data = graphQLResult.data else {
                return .failure(DashXClientError.customError(message: "The server returned no data"))
            }
            return .success(map(data))
        case .failure(let error):
            DashXLog.e(tag: "DashXChat", "Request failed: \(error)")
            return .failure(DashXClientError.networkError(underlying: error))
        }
    }
}

extension DashXChatMessage {
    init(fragment: DashXGql.ChatMessageFragment) {
        self.init(
            id: fragment.id,
            conversationId: fragment.conversationId ?? "",
            externalUid: fragment.externalUid,
            senderId: fragment.senderId,
            aiRole: fragment.aiRole,
            turnSeq: fragment.turnSeq,
            renderedContent: DashXClient.fromJSONScalar(fragment.renderedContent),
            createdAt: fragment.createdAt,
            sentAt: fragment.sentAt
        )
    }
}

extension DashXChatConversationSummary {
    init(fragment: DashXGql.ChatConversationSummaryFragment) {
        self.init(
            conversationId: fragment.conversationId,
            category: fragment.category,
            context: fragment.context.map {
                Context(kind: $0.kind, subtype: $0.subtype, id: $0.id, reference: $0.reference, name: $0.name)
            },
            topic: fragment.topic.map { Topic(id: $0.id, label: $0.label) },
            status: fragment.status,
            title: fragment.title,
            lastMessagePreview: fragment.lastMessagePreview,
            lastMessageAt: fragment.lastMessageAt,
            lastSenderKind: fragment.lastSenderKind,
            activityAt: fragment.activityAt,
            assignedGroups: fragment.assignedGroups.map { AssignedGroup(id: $0.id, name: $0.name) },
            unreadCount: fragment.unreadCount
        )
    }
}
