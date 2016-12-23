import Foundation

//Guild Type
public struct Guild {

  private let sword: Sword

  public let afkChannelId: String?
  public let afkTimeout: Int?
  public internal(set) var channels: [String: Channel] = [:]
  public let defaultMessageNotifications: Int
  public let embedChannelId: Int?
  public let embedEnabled: Bool?
  public internal(set) var emojis: [Emoji] = []
  public private(set) var features: [String] = []
  public let icon: String?
  public let id: String
  public let joinedAt: Date?
  public let large: Bool?
  public let memberCount: Int
  public internal(set) var members: [String: Member] = [:]
  public let mfaLevel: Int
  public let name: String
  public let ownerId: String
  public let region: String
  public internal(set) var roles: [String: Role] = [:]
  public let shard: Int?
  public let splash: String?
  public let verificationLevel: Int

  /* Creates Guild struct
    @param sword: Sword - Parent class to get requester from
    @param json: [String: Any] - JSON to decode into struct
    @param shard: Int? - ID of shard to assign guild
  */
  init(_ sword: Sword, _ json: [String: Any], _ shard: Int? = nil) {
    self.sword = sword

    self.afkChannelId = json["afk_channel_id"] as? String
    self.afkTimeout = json["afk_timeout"] as? Int

    if let channels = json["channels"] as? [[String: Any]] {
      for channel in channels {
        self.channels[channel["id"] as! String] = Channel(sword, channel)
      }
    }

    self.defaultMessageNotifications = json["default_message_notifications"] as! Int
    self.embedChannelId = json["embed_channel_id"] as? Int
    self.embedEnabled = json["embed_enabled"] as? Bool

    if let emojis = json["emojis"] as? [[String: Any]] {
      for emoji in emojis {
        self.emojis.append(Emoji(emoji))
      }
    }

    if let features = json["features"] as? [String] {
      for feature in features {
        self.features.append(feature)
      }
    }

    self.icon = json["icon"] as? String
    self.id = json["id"] as! String

    if let joinedAt = json["joined_at"] as? String {
      self.joinedAt = joinedAt.date
    }else {
      self.joinedAt = nil
    }

    self.large = json["large"] as? Bool
    self.memberCount = json["member_count"] as! Int

    if let members = json["members"] as? [[String: Any]] {
      for member in members {
        self.members[(member["user"] as! [String: Any])["id"] as! String] = Member(sword, member)
      }
    }

    self.mfaLevel = json["mfa_level"] as! Int
    self.name = json["name"] as! String
    self.ownerId = json["owner_id"] as! String
    self.region = json["region"] as! String

    let roles = json["roles"] as! [[String: Any]]
    for role in roles {
      let role = Role(role)
      self.roles[role.id] = role
    }

    self.shard = shard
    self.splash = json["splash"] as? String
    self.verificationLevel = json["verification_level"] as! Int
  }

  /* Addds a user to this guild
    @param userId: String - User to add
    @param options: [String: Any] - Initial options to give member
  */
  public func add(member userId: String, with options: [String: Any] = [:], _ completion: @escaping (Member?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.addGuildMember(self.id, userId), body: options.createBody(), method: "PUT") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(Member(self.sword, data as! [String: Any]))
      }
    }
  }

  /* Bans a user on a guild
    @param userId: String - User to ban
    @param options: [String: Int] - Options for ban
  */
  public func ban(member userId: String, with options: [String: Int] = [:], _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.createGuildBan(self.id, userId), body: options.createBody(), method: "PUT") { error, data in
      if error == nil { completion() }
    }
  }

  /* Creates a channel in this guild
    @param options: [String: Any] - Options to give new channel
  */
  public func createChannel(with options: [String: Any], _ completion: @escaping (Channel?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.createGuildChannel(self.id), body: options.createBody(), method: "POST") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(Channel(self.sword, data as! [String: Any]))
      }
    }
  }

  /* Creates guild integration from user
    @param options: [String: String] - Integration info from user
  */
  public func createIntegration(with options: [String: String], _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.createGuildIntegration(self.id), body: options.createBody(), method: "POST") { error, data in
      if error == nil { completion() }
    }
  }

  //Creates a guild role
  public func createRole(_ completion: @escaping (Role?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.createGuildRole(self.id), method: "POST") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(Role(data as! [String: Any]))
      }
    }
  }

  /* Deletes a guild integration
    @param integrationId: String - Integration to delete
  */
  public func delete(integration integrationId: String, _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.deleteGuildIntegration(self.id, integrationId), method: "DELETE") { error, data in
      if error == nil { completion() }
    }
  }

  /* Deletes a guild role
    @param roleId: String - Role to delete
  */
  public func delete(role roleId: String, _ completion: @escaping (Role?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.deleteGuildRole(self.id, roleId), method: "DELETE") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(Role(data as! [String: Any]))
      }
    }
  }

  // Deletes current guild
  public func delete(_ completion: @escaping (Guild?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.deleteGuild(self.id), method: "DELETE") { error, data in
      if error != nil {
        completion(nil)
      }else {
        let guild = Guild(self.sword, data as! [String: Any], self.shard)
        self.sword.guilds.removeValue(forKey: self.id)
        completion(guild)
      }
    }
  }

  // Gets guild's bans
  public func getBans(_ completion: @escaping ([User]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildBans(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        var returnUsers: [User] = []
        let users = data as! [[String: Any]]
        for user in users {
          returnUsers.append(User(self.sword, user))
        }

        completion(returnUsers)
      }
    }
  }

  // Gets the guild embed
  public func getEmbed(_ completion: @escaping ([String: Any]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildEmbed(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? [String: Any])
      }
    }
  }

  //Gets guild's integrations
  public func getIntegrations(_ completion: @escaping ([[String: Any]]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildIntegrations(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? [[String: Any]])
      }
    }
  }

  //Gets guild's invites
  public func getInvites(_ completion: @escaping ([[String: Any]]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildInvites(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? [[String: Any]])
      }
    }
  }

  // Gets an array of guild members
  public func getMembers(_ completion: @escaping ([Member]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.listGuildMembers(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        var returnMembers: [Member] = []
        let members = data as! [[String: Any]]
        for member in members {
          returnMembers.append(Member(self.sword, member))
        }

        completion(returnMembers)
      }
    }
  }

  /* Gets number of members for x amount of prune days
    @param limit: Int - Amount of days to get pruned members for
  */
  public func getPruneCount(for limit: Int, _ completion: @escaping (Int?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.getGuildPruneCount(self.id), body: ["days": limit].createBody()) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? Int)
      }
    }
  }

  //Gets guild roles
  public func getRoles(_ completion: @escaping ([Role]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildRoles(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        var returnRoles: [Role] = []
        let roles = data as! [[String: Any]]
        for role in roles {
          returnRoles.append(Role(role))
        }

        completion(returnRoles)
      }
    }
  }

  // Gets an array of voice regions from guild
  public func getVoiceRegions(_ completion: @escaping ([[String: Any]]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildVoiceRegions(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? [[String: Any]])
      }
    }
  }

  //Gets guild's webhooks
  public func getWebhooks(_ completion: @escaping ([[String: Any]]?) -> ()) {
    self.sword.requester.request(self.sword.endpoints.getGuildWebhooks(self.id)) { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? [[String: Any]])
      }
    }
  }

  /* Modifies guild integration
    @param integrationId: String - Integration to update
    @param options: [String: Any] - Options to apply to integration
  */
  public func modify(integration integrationId: String, with options: [String: Any], _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuildIntegration(self.id, integrationId), body: options.createBody(), method: "PATCH") { error, data in
      if error == nil { completion() }
    }
  }

  /* Modifies guild member
    @param userId: String - User to modify
    @param options: [String: Any] - Options to modify user with
  */
  public func modify(member userId: String, with options: [String: Any], _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuildMember(self.id, userId), body: options.createBody(), method: "PATCH") { error, data in
      if error == nil { completion() }
    }
  }

  /* Modifes guild role
    @param roleId: String - Role to modify
    @param options: [String: Any] - Options to modify role with
  */
  public func modify(role roleId: String, with options: [String: Any], _ completion: @escaping (Role?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuildRole(self.id, roleId), body: options.createBody(), method: "PATCH") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(Role(data as! [String: Any]))
      }
    }
  }

  /* Modifies current guild
    @param options: [String: Any] - Options to modify guild with
  */
  public func modify(with options: [String: Any], _ completion: @escaping (Guild?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuild(self.id), body: options.createBody(), method: "PATCH") { error, data in
      if error != nil {
        completion(nil)
      }else {
        let guild = Guild(self.sword, data as! [String: Any], self.shard)
        self.sword.guilds[self.id] = guild
        completion(guild)
      }
    }
  }

  /* Modifes the order in which guild channels show up in
    @param options: [[String: Any]] - Array of channel positions
  */
  public func modifyChannelPositions(with options: [[String: Any]], _ completion: @escaping ([Channel]?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuildChannelPositions(self.id), body: options.createBody(), method: "PATCH") { error, data in
      if error != nil {
        completion(nil)
      }else {
        var returnChannels: [Channel] = []
        let channels = data as! [[String: Any]]
        for channel in channels {
          returnChannels.append(Channel(self.sword, channel))
        }

        completion(returnChannels)
      }
    }
  }

  /* Modifes guild role positions
    @param options: [[String: Any]] - Array of role positions
  */
  public func modifyRolePositions(with options: [[String: Any]], _ completion: @escaping ([Role]?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.modifyGuildRolePositions(self.id), body: options.createBody(), method: "PATCH") { error, data in
      if error != nil {
        completion(nil)
      }else {
        var returnRoles: [Role] = []
        let roles = data as! [[String: Any]]
        for role in roles {
          returnRoles.append(Role(role))
        }

        completion(returnRoles)
      }
    }
  }

  /* Prunes members for x amount of days
    @param limit: Int - Amount of days to prune members for
  */
  public func prune(for limit: Int, _ completion: @escaping (Int?) -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.beginGuildPrune(self.id), body: ["days": limit].createBody(), method: "POST") { error, data in
      if error != nil {
        completion(nil)
      }else {
        completion(data as? Int)
      }
    }
  }

  /* Removes a member from guild
    @param userId: String - User to remove
  */
  public func remove(member userId: String, _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.removeGuildMember(self.id, userId), method: "DELETE") { error, data in
      if error == nil { completion() }
    }
  }

  /* Syncs a guild integration
    @param integrationId: String - Integration to sync
  */
  public func sync(integration integrationId: String, _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.syncGuildIntegration(self.id, integrationId), method: "POST") { error, data in
      if error == nil { completion() }
    }
  }

  /* Removes a ban from user
    @param userId: String - User to unban
  */
  public func unban(member userId: String, _ completion: @escaping () -> () = {_ in}) {
    self.sword.requester.request(self.sword.endpoints.removeGuildBan(self.id, userId), method: "DELETE") { error, data in
      if error == nil { completion() }
    }
  }

}

//UnavailableGuild Type
public struct UnavailableGuild {

  let id: Int
  let shard: Int
  let unavailable: Bool

  /* Creates UnavailableGuild struct
    @param json: [String: Any] - JSON to decode into struct
    @param shard: Int - ID of shard to assign guild
  */
  init(_ json: [String: Any], _ shard: Int) {
    self.id = Int(json["id"] as! String)!
    self.shard = shard
    self.unavailable = json["unavailable"] as! Bool
  }

}

//Emoji Type
public struct Emoji {

  public let id: String
  public let managed: Bool
  public let name: String
  public let requireColons: Bool
  public var roles: [Role] = []

  /* Creates Emoji struct
    @param json: [String: Any] - JSON to decode into struct
  */
  init(_ json: [String: Any]) {
    self.id = json["id"] as! String
    self.managed = json["managed"] as! Bool
    self.name = json["name"] as! String
    self.requireColons = json["require_colons"] as! Bool

    if let roles = json["roles"] as? [[String: Any]] {
      for role in roles {
        self.roles.append(Role(role))
      }
    }
  }

}