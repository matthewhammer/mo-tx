import NftTypes "../nft_collection/Types";
import Types "Types";
import State "State";
import Array "mo:base/Array";
import Principal "mo:base/Principal";

module {
  public type OwnedNft = Types.OwnedNft;
  public type NftCollection = NftTypes.NftCollection;
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
                    for (send in plan.sends.vals()) {
                      let a = collectionActor(send.nft.collection).send(send.nft.id, send.target);
                      assert (await a);
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

    func collectionActor(p : Principal) : NftCollection {
      actor (Principal.toText(p));
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
        size + 1,
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
