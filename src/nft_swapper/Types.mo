import NCTypes "../nft_collection/Types";

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
    timeWindow : (Int, Int);
    swap2Reqs : [Swap2Req];
  };

  // States of a "flow" through
  // the Swapper multi-canister protocol.
  public module State {
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

    // 3. After Validated,
    // one or more Nfts have
    // been transferred to Swapper.
    // 2 --> 3 requires only a transfer of
    // any Nft mentioned in Plan.
    public type Resourcing = {
      plan : Plan;
      have : [Nft];
      awaiting : [OwnedNft];
    };

    // When we are Resourcing for too long,
    // and we miss the timeWindow in the Plan.
    // (Now need to send Nfts back to original owners.)
    public type TimeOut = {
      plan : Plan;
      have : [Nft];
      awaiting : [OwnedNft];
    };

    // 4. Running plan.
    // 3 --> 4 requires that all Nfts
    // in plan are transferred to Swapper.
    public type Running = {
      plan : Plan;
    };

    // 5. Completed plan.
    // 5 --> 6 requires that each swap in plan is processed
    // by its respective NFT collection canister.
    public type Complete = {
      plan : Plan;
    };

    public type State = {
      #submit : Submit;
      #invalid : Invalid;
      #valid : Valid;
      #resourcing : Resourcing;
      #timeOut : TimeOut;
      #running : Running;
      #complete : Complete;
    }

  };
};
