import NftTypes "../nft_collection/Types";
import Types "Types";
import State "State";

module {
  public type Plan = Types.Plan;

  public class Core(stableState : State.State) {

    public func submitPlan(caller : Principal, plan : Plan) : Bool {
      false;
    };
  }

};
