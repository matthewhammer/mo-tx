import NftTypes "../nft_collection/Types";
import Types "Types";
import Core "Core";
import State "State";

// Using optional arg type lets dfx / motoko dev server do deploy without any args.
shared ({ caller = installer }) actor class NftSwapper() {

  stable var state = State.init(installer);

  let core = Core.Core(installer, state);

  type Plan = Types.Plan;

};
