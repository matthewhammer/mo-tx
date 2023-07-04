import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Types "Types";
import Debug "mo:base/Debug";

shared ({ caller = installer }) actor class NftCollection() {
  public type NftId = Types.NftId;
  stable var ownerMap : Trie.Trie<NftId, Principal> = Trie.empty();
  let idEq = func(a : NftId, b : NftId) : Bool { a == b };

  func key((#nft id) : NftId) : Trie.Key<NftId> {
    { hash = Text.hash id; key = #nft id };
  };

  func findOwner(id : NftId) : ?Principal {
    Trie.find(ownerMap, key(id), idEq);
  };

  func setOwner(id : NftId, newOwner : Principal) {
    ownerMap := Trie.put(ownerMap, key(id), idEq, newOwner).0;
  };

  public shared ({ caller }) func create(id : NftId, newOwner : Principal) : async Bool {
    if (caller == installer) {
      if (findOwner(id) == null) {
        setOwner(id, newOwner);
        true;
      } else false;
    } else false;
  };

  func send_(caller : Principal, id : NftId, newOwner : Principal) : Bool {
    if (findOwner(id) == ?caller or caller == installer) {
      setOwner(id, newOwner);
      true;
    } else {
      false;
    };
  };

  public shared ({ caller }) func send(id : NftId, newOwner : Principal) : async Bool {
    send_(caller, id, newOwner);
  };

  public shared ({ caller }) func installerSend(id : NftId, newOwner : Principal) : async Bool {
    if (caller == installer) {
      send_(caller, id, newOwner);
    } else false;
  };

  public shared query func getOwner(id : NftId) : async ?Principal {
    findOwner(id);
  };

};
