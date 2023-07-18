import Principal "mo:base/Principal";
import State "../src/nft_swapper/State";
import { NftCollection } "../src/nft_collection/Main";
import NftSwapper "../src/nft_swapper/Core";
import NftSwapperTypes "../src/nft_swapper/Types";
import D "mo:base/Debug";

let planIsBeingSubmitted = NftSwapperTypes.PlanState.planIsBeingSubmitted;
let planIsResourcing = NftSwapperTypes.PlanState.planIsResourcing;

let alice = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
let bob = Principal.fromText("renrk-eyaaa-aaaaa-aaada-cai");
let installer = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");
let swapperPrincipal = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

// Two collections, c1 and c2
let c1 = await NftCollection();
let c2 = await NftCollection();

assert await c1.create(#nft "ape42", alice);
assert await c2.create(#nft "baboon13", bob);

let n1 = { id = #nft "ape42"; collection = Principal.fromActor(c1) };
let on1 = { owner = alice; nft = n1 };

let n2 = { id = #nft "baboon13"; collection = Principal.fromActor(c2) };
let on2 = { owner = bob; nft = n2 };

let swapper = NftSwapper.Core(installer, State.init(installer));

let thePlan = {
  sends = [
    {
      source = alice;
      nft = n1;
      target = bob;
    },
    {
      source = bob;
      nft = n2;
      target = alice;
    },
  ];
};

let alicesPart = async {
  assert await swapper.submitPlan(alice, thePlan);
};

let bobsPart = async {
  while (swapper.getPlan(swapperPrincipal, thePlan) == null) {
    await async {};
  };
  assert (await swapper.cancelPlan(bob, thePlan));
};

await alicesPart;
await bobsPart;

let ?p = swapper.getPlan(swapperPrincipal, thePlan) else {
  assert false;
  loop {};
};
assert (switch (p.current) { case (#cancelled(_)) true; case _ false });

assert (await c1.getOwner(#nft "ape42")) == ?alice;
assert (await c2.getOwner(#nft "baboon13")) == ?bob;
