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

  // Two-way swap.
  // Only valid if ownership claims
  // are valid when activated.
  public type Swap2Req = {
    ownedNft1 : OwnedNft;
    ownedNft2 : OwnedNft;
  };

  // A plan is a sequence of two-way swaps.
  // It is valid if run as a sequence, it is valid.
  public type Plan = {
    swap2Reqs : [Swap2Req];
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

    // 2. After Submitted,
    // the plan is valid with respect
    // to the ownership claims it makes.
    // 1 --> 2 requires that:
    //  - every Principal mentioned in plan submits the same one.
    //  - each collection
    //    is queried for respective claims,
    //    and they all are valid.
    public type Valid = {
      plan : Plan;
    };

    // If a single Plan is invalid, for any submission of it, by anyone.
    public type Invalid = {
      parties : [Principal];
      plan : Plan;
      // "NFT blah is not owned by who the plan claims in step 5".
      reason : Text;
    };

    // 3. After Valid,    //
    // one or more Nfts have
    // been transferred to Swapper.
    // 2 --> 3 requires only a transfer of
    // any Nft mentioned in Plan.
    //
    // NB: Each party waits for Valid or Resourcing before
    // doing any transfers -- otherwise, they change the collections'
    // state too soon, and interfere with the necessarily validity checks
    // about initial ownership.
    public type Resourcing = {
      plan : Plan;
      have : [OwnedNft]; // <-- Save old owner here for a bit, in case we need to roll back.
    };

    //
    // (Now need to send Nfts back to original owners, somehow.)
    public type Cancelled = {
      plan : Plan;
      have : [OwnedNft]; // <-- Each NFT that we need to refund now.
    };

    // 4. Running plan.
    // 3 --> 4 requires that all Nfts
    // in plan are transferred to Swapper.
    public type Running = {
      plan : Plan;
    };

    // 5. Completed plan.
    // 4 --> 5 requires that each swap in plan is processed
    // by its respective NFT collection canister.
    public type Complete = {
      plan : Plan;
    };

    public type PlanState = {
      #submit : Submit;
      #invalid : Invalid;
      #valid : Valid;
      #resourcing : Resourcing;
      #cancelled : Cancelled;
      #running : Running;
      #complete : Complete;
    }

  };
};
