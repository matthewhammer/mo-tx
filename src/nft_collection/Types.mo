module {
  public type NftId = { #nft : Text };

  public type NftCollection = actor {
    send : (NftId, Principal) -> async Bool;
    getOwner : query NftId -> async ?Principal;
  };

  public type Nft = { id : NftId; collection : Principal };
};
