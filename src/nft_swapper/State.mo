import NftTypes "../nft_collection/Types";
import Types "Types";

import Trie "mo:base/Trie";
import Array "mo:base/Array";

module {
  public type Plan = Types.Plan;
  public type PlanState = Types.PlanState.PlanState;
  public type PlanStates = Types.PlanState.PlanStates;

  public type State = {
    installer : Principal;
    var plans : Trie.Trie<Plan, PlanStates>;
  };

  public func init(installer : Principal) : State {
    { installer; var plans = Trie.empty() };
  };

  public class OOState(state : State) {
    public func putPlan(plan : Plan, newState : PlanState) {
      switch (Trie.get<Plan, PlanStates>(state.plans, Types.planKey(plan), Types.planEq)) {
        case null {
          let s = {
            current = newState;
            past = [];
          };
          state.plans := Trie.put<Plan, PlanStates>(state.plans, Types.planKey(plan), Types.planEq, s).0;
        };
        case (?planStates) {
          let s = {
            current = newState;
            past = addState(planStates.past, planStates.current);
          };
          state.plans := Trie.put<Plan, PlanStates>(state.plans, Types.planKey(plan), Types.planEq, s).0;
        };
      };
    };

    public func getPlan(plan : Plan) : ?PlanStates {
      Trie.get<Plan, PlanStates>(state.plans, Types.planKey(plan), Types.planEq);
    };

    // to do -- generalize -- see Core (addParty).
    func addState(states : [PlanState], state : PlanState) : [PlanState] {
      let size = states.size();
      Array.tabulate<PlanState>(
        size + 1,
        func i {
          if (i < size) {
            states[i];
          } else {
            state;
          };
        },
      );
    };

  };
};
