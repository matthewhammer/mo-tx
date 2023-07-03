import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Types "Types";

shared ({ caller = installer }) actor class () {
  public type NftId = Types.NftId;
  stable var ownerMap : Trie.Trie<NftId, Principal> = Trie.empty();
  let idEq = func(a : NftId, b : NftId) : Bool { a == b };

  func key((#NftId id) : NftId) : Trie.Key<NftId> {
    { hash = Text.hash id; key = #NftId id };
  };

  func find(id : NftId) : ?Principal {
    Trie.find(ownerMap, key(id), idEq);
  };

  func setOwner(id : NftId, newOwner : Principal) {
    ownerMap := Trie.put(ownerMap, key(id), idEq, newOwner).0;
  };

  public shared ({ caller }) func create(id : NftId, newOwner : Principal) : async Bool {
    if (caller == installer) {
      if (find(id) == null) {
        setOwner(id, newOwner);
        true;
      } else false;
    } else false;
  };

  public shared ({ caller }) func send(id : NftId, newOwner : Principal) : async Bool {
    if (find(id) == ?caller) {
      setOwner(id, newOwner);
      true;
    } else {
      false;
    };
  };

    public shared query func getOwner(id : NftId) : async ?Principal {
        find(id)
    };

};
