import NftTypes "../nft_collection/Types";
import Types "Types";
import State "State";
import Array "mo:base/Array";
import Principal "mo:base/Principal";
import ArraySet "../common/ArraySet";

module {
  public type OwnedNft = Types.OwnedNft;
  public type NftCollection = NftTypes.NftCollection;
  public type Plan = Types.Plan;
  public type PlanState = State.PlanStates;

  public class Core(installer : Principal, stableState : State.State) {

    let state = State.OOState(stableState);

    public func ownedNftSet(ns : [OwnedNft]) : ArraySet.ArraySet<OwnedNft> {
      ArraySet.ArraySet(
        ns,
        func(n1 : OwnedNft, n2 : OwnedNft) : Bool { n1 == n2 },
      );
    };

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
              let parties = ArraySet.principalSet(submit.parties);
              if (parties.isMember(caller)) {
                // caller is already among the parties.  No change.
                true;
              } else {
                let newParties = parties.add(caller);

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
              let have = ownedNftSet(resourcing.have);
              if (have.isMember(nft)) {
                // nft is already among the nfts.  No change.
                true;
              } else {
                let newNfts = have.add(nft);
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
                  state.putPlan(plan, #resourcing { plan; have = have.add(nft) });
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

  };
};
