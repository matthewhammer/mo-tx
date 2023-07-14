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

// send resources to plan (via swapper)

let alicesPart = async {
  // Alice does this stuff:
  assert swapper.submitPlan(alice, thePlan);

  // wait until plan is resourcing.
  while (planIsBeingSubmitted(swapper.getPlan(alice, thePlan))) {
    // To do -- Tell Alice things as we wait.
    await async {}; // NB: Need this, to yeild control to other block, below.
  };
  if (not planIsResourcing(swapper.getPlan(alice, thePlan))) { assert false };

  assert (await c1.installerSend(#nft "ape42", swapperPrincipal)); // to do -- alice sends.
  D.print(debug_show swapper.getPlan(alice, thePlan));
  assert (await swapper.notifyPlan(alice, thePlan, on1));
};

let bobsPart = async {
  // Bob does this stuff:
  assert swapper.submitPlan(bob, thePlan);

  // wait until plan is resourcing.
  while (planIsBeingSubmitted(swapper.getPlan(bob, thePlan))) {
    // To do -- Tell Bob things as we wait.
    await async {};
  };
  if (not planIsResourcing(swapper.getPlan(alice, thePlan))) { assert false };

  assert (await c2.installerSend(#nft "baboon13", swapperPrincipal)); // to do -- bob sends.
  D.print(debug_show swapper.getPlan(bob, thePlan));
  assert (await swapper.notifyPlan(bob, thePlan, on2)); // plan executes here (assuming this happens after Alice).
};

await alicesPart;
await bobsPart;

let p = swapper.getPlan(swapperPrincipal, thePlan);

// to do --assert that plan p is #complete

assert (await c1.getOwner(#nft "ape42")) == ?bob;
assert (await c2.getOwner(#nft "baboon13")) == ?alice;