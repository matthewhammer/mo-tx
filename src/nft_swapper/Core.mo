import NftTypes "../nft_collection/Types";
import Types "Types";
import State "State";
import Array "mo:base/Array";

module {
  public type Plan = Types.Plan;

  public class Core(installer : Principal, stableState : State.State) {

    let state = State.OOState(stableState);

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
                state.putPlan(plan, #submit { plan; parties = addParty(submit.parties, caller) });
                true;
              };
            };
            case _ { false };
          };
        };
      };
    };

    func addParty(parties : [Principal], party : Principal) : [Principal] {
      let size = parties.size();
      Array.tabulate<Principal>(
        size,
        func i {
          if (i < size) {
            parties[i];
          } else {
            party;
          };
        },
      );
    };

  }

};
