import NftTypes "../nft_collection/Types";
import Types "Types";
import State "State";
import Array "mo:base/Array";

module {
  public type OwnedNft = Types.OwnedNft;
  public type Plan = Types.Plan;
  public type PlanState = State.PlanStates;

  public class Core(installer : Principal, stableState : State.State) {

    let state = State.OOState(stableState);

    public func getPlan(caller : Principal, plan : Plan) : ?PlanState {
      // to do -- access control.
      state.getPlan(plan);
    };

    public func submitPlan(caller : Principal, plan : Plan) : Bool {
      switch (state.getPlan(plan)) {
        case null {
          state.putPlan(
            plan,
            #submit {
              plan;
              parties = [caller];
            },
          );
          true;
        };
        case (?planStates) {
          switch (planStates.current) {
            case (#submit(submit)) {
              if (Array.find(submit.parties, func(p : Principal) : Bool { p == caller }) != null) {
                // caller is already among the parties.  No change.
                true;
              } else {
                let newParties = addParty(submit.parties, caller);

                if (newParties.size() == 2 /* to do: newParties == current.parties (set operation) */) {
                  state.putPlan(plan, #resourcing { plan; parties = []; have = [] });
                  true;
                } else {
                  state.putPlan(plan, #submit { plan; parties = newParties });
                  true;
                };
              };
            };
            case _ { false };
          };
        };
      };
    };

    public func notifyPlan(caller : Principal, plan : Plan, nft : OwnedNft) : async Bool {
      switch (state.getPlan(plan)) {
        case null { false };
        case (?s) {
          switch (s.current) {
            case (#resourcing(resourcing)) {
              if (Array.find(resourcing.have, func(n : OwnedNft) : Bool { n == nft }) != null) {
                // nft is already among the nfts.  No change.
                true;
              } else {
                let newNfts = addNft(resourcing.have, nft);
                if (newNfts.size() == 2 /* to do */) {
                  state.putPlan(plan, #running { plan });
                  do {
                    for (swap in plan.swap2Reqs.vals()) {
                      let { owner = o1; nft = { id = i1; collection = c1 } } = swap.ownedNft1;
                      let { owner = o2; nft = { id = i2; collection = c2 } } = swap.ownedNft2;
                      let a1 = (actor c1).send(i1, o2);
                      let a2 = (actor c2).send(i2, o1);
                      assert (await a1);
                      assert (await a2);
                    };
                  };
                  state.putPlan(plan, #complete { plan });
                  true;
                } else {
                  state.putPlan(plan, #resourcing { plan; have = addNft(resourcing.have, nft) });
                  true;
                };
              };
            };
            case _ { false };
          };
        };
      };
    };

    func addParty(parties : [Principal], party : Principal) : [Principal] {
      arrayAdd(parties, party);
    };

    func addNft(nfts : [OwnedNft], nft : OwnedNft) : [OwnedNft] {
      arrayAdd(nfts, nft);
    };

    func arrayAdd<X>(a : [X], x : X) : [X] {
      let size = a.size();
      Array.tabulate<X>(
        size,
        func i {
          if (i < size) {
            a[i];
          } else {
            x;
          };
        },
      );
    };

  };
};
