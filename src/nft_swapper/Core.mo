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

    func callerMayAccessPlan(caller : Principal, plan : Plan) : Bool {
      caller == installer or ArraySet.principalSet(Types.planParties(plan)).has(caller);
    };

    public func getPlan(caller : Principal, plan : Plan) : ?PlanState {
      if (not callerMayAccessPlan(caller, plan)) null else state.getPlan(plan);
    };

    func refundOwnedNft(n : OwnedNft) : async () {
      assert (await collectionActor(n.nft.collection).send(n.nft.id, n.owner));
    };

    func refundOwnedNfts(nfts : [OwnedNft]) : async () {
      for (n in nfts.vals()) {
        await refundOwnedNft(n);
      };
    };

    func checkPlanSubmit(plan : Plan) : async Bool {
      for (send in plan.sends.vals()) {
        let actualOwner = await collectionActor(send.nft.collection).getOwner(send.nft.id);
        if (actualOwner != ?send.source) {
          return false;
        };
      };
      true;
    };

    public func submitPlan(caller : Principal, plan : Plan) : async Bool {
      if (not callerMayAccessPlan(caller, plan)) { return false };
      if (not (await checkPlanSubmit(plan))) {
        state.putPlan(
          plan,
          #invalidSubmit {
            parties = [caller];
          },
        );
        return false;
      };
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
              if (parties.has(caller)) {
                // caller is already among the parties.  No change.
                true;
              } else {
                let newParties = parties.add(caller);
                if (ArraySet.principalSet(newParties).equals(Types.planParties(plan))) {
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
      if (not callerMayAccessPlan(caller, plan)) { return false };
      switch (state.getPlan(plan)) {
        case null { false };
        case (?s) {
          switch (s.current) {
            case (#cancelled(cancelled)) {
              if (caller == nft.owner) {
                await refundOwnedNft(nft);
                true;
              } else false;
            };

            case (#resourcing(resourcing)) {
              let have = Types.ownedNftSet(resourcing.have);
              if (have.has(nft)) {
                // nft is already among the nfts.  No change.
                true;
              } else {
                let newNfts = have.add(nft);
                if (Types.ownedNftSet(newNfts).equals(Types.planOwnedNfts(plan))) {
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

    public func cancelPlan(caller : Principal, plan : Plan) : async Bool {
      if (not callerMayAccessPlan(caller, plan)) { return false };
      switch (state.getPlan(plan)) {
        case null { false };
        case (?s) {
          switch (s.current) {
            case (#cancelled(_)) { /* already canceled */ true };
            case (#submit(submit)) {
              state.putPlan(plan, #cancelled { plan; by = caller; refunded = [] });
              true;
            };
            case (#resourcing(resourcing)) {
              await refundOwnedNfts(resourcing.have);
              state.putPlan(plan, #cancelled { plan; by = caller; refunded = resourcing.have });
              true;
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
