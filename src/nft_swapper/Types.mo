import NCTypes "../nft_collection/Types";
import Blob "mo:base/Blob";
import Trie "mo:base/Trie";

module {

  // An NFT ID
  // with a collection service
  // where that ID makes sense.
  public type Nft = NCTypes.Nft;

  // An NFT with an attached ownership assertion.
  public type OwnedNft = {
    owner : Principal;
    nft : Nft;
  };

  public type Send = {
    source : Principal;
    target : Principal;
    nft : Nft;
  };

  // A plan is a sequence of two-way swaps.
  // It is valid if run as a sequence, it is valid.
  public type Plan = {
    sends : [Send];
  };

  public func planKey(p : Plan) : Trie.Key<Plan> {
    {
      hash = planHash(p);
      key = p;
    };
  };

  public func planHash(p : Plan) : Nat32 {
    // Blob.hash(to_candid(p))
    0 // Using a constant hash function to overcome moc interpreter missing to_candid.
  };

  public func planEq(p1 : Plan, p2 : Plan) : Bool {
    p1 == p2;
  };

  // States of a "flow" through
  // the Swapper multi-canister protocol.
  public module PlanState {
    // 1. One or more parties
    // have submitted a plan.
    public type Submit = {
      plan : Plan;
      parties : [Principal];
    };

    // If a single Plan is invalid, for any submission of it, by anyone.
    public type Invalid = {
      parties : [Principal];
      plan : Plan;
      // "NFT blah is not owned by who the plan claims in step 5".
      reason : Text;
    };

    public type Resourcing = {
      plan : Plan;
      have : [OwnedNft]; // <-- Save old owner here for a bit, in case we need to roll back.
    };

    public type Cancelled = {
      plan : Plan;
      by : Principal;
    };

    public type Running = {
      plan : Plan;
      // to do -- list completed swaps thus far here.
    };

    public type Complete = {
      plan : Plan;
    };

    public type PlanState = {
      //
      // Intermediate states of a plan's execution:
      //
      #submit : Submit;
      #resourcing : Resourcing;
      #running : Running;

      //
      // Plan outcomes:
      //
      #invalid : Invalid;
      #cancelled : Cancelled;
      #complete : Complete;
    };

    public type PlanStates = {
      past : [PlanState];
      current : PlanState;
    };

    public func planIsBeingSubmitted(ps : ?PlanStates) : Bool {
      switch (ps) {
        case null true;
        case (?ps) {
          switch (ps.current) {
            case (#submit(_)) { true };
            case _ { false };
          };
        };
      };
    };

    public func planIsResourcing(ps : ?PlanStates) : Bool {
      switch (ps) {
        case null false;
        case (?ps) {
          switch (ps.current) {
            case (#resourcing(_)) { true };
            case _ { false };
          };
        };
      };
    };

  };
};
