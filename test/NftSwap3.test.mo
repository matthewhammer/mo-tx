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
let chuck = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

let installer = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");
let swapperPrincipal = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

// Two collections, c1 and c2
let c1 = await NftCollection();
let c2 = await NftCollection();
let c3 = await NftCollection();

assert await c1.create(#nft "ape42", alice);
assert await c2.create(#nft "baboon13", bob);
assert await c3.create(#nft "alien51", chuck);

let n1 = { id = #nft "ape42"; collection = Principal.fromActor(c1) };
let on1 = { owner = alice; nft = n1 };

let n2 = { id = #nft "baboon13"; collection = Principal.fromActor(c2) };
let on2 = { owner = bob; nft = n2 };

let n3 = { id = #nft "alien51"; collection = Principal.fromActor(c3) };
let on3 = { owner = chuck; nft = n3 };

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
      target = chuck;
    },
    {
      source = chuck;
      nft = n3;
      target = alice;
    },
  ];
};

// Each user submits the plan
assert await swapper.submitPlan(alice, thePlan);
assert await swapper.submitPlan(bob, thePlan);
assert await swapper.submitPlan(chuck, thePlan);

// send resources to plan (via swapper)

let alicesPart = async {
  // verify that plan is resourcing.
  assert not planIsBeingSubmitted(swapper.getPlan(alice, thePlan));
  assert planIsResourcing(swapper.getPlan(alice, thePlan));

  // Alice does this stuff:
  assert (await c1.installerSend(#nft "ape42", swapperPrincipal)); // to do -- alice sends.
  D.print(debug_show swapper.getPlan(alice, thePlan));
  assert (await swapper.notifyPlan(alice, thePlan, on1));
};

let bobsPart = async {
  // verify that plan is resourcing.
  assert not planIsBeingSubmitted(swapper.getPlan(bob, thePlan));
  assert planIsResourcing(swapper.getPlan(bob, thePlan));

  // Bob does this stuff:
  assert (await c2.installerSend(#nft "baboon13", swapperPrincipal)); // to do -- bob sends.
  D.print(debug_show swapper.getPlan(bob, thePlan));
  assert (await swapper.notifyPlan(bob, thePlan, on2)); // plan executes here (assuming this happens after Alice).
};

let chucksPart = async {
  // verify that plan is resourcing.
  assert not planIsBeingSubmitted(swapper.getPlan(chuck, thePlan));
  assert planIsResourcing(swapper.getPlan(chuck, thePlan));

  // Chuck does this stuff:
  assert (await c3.installerSend(#nft "alien51", swapperPrincipal)); // to do -- bob sends.
  D.print(debug_show swapper.getPlan(chuck, thePlan));
  assert (await swapper.notifyPlan(chuck, thePlan, on3)); // plan executes here (assuming this happens after Alice).
};

await alicesPart;
await bobsPart;
await chucksPart;

let p = swapper.getPlan(swapperPrincipal, thePlan);

// to do --assert that plan p is #complete

assert (await c1.getOwner(#nft "ape42")) == ?bob;
assert (await c2.getOwner(#nft "baboon13")) == ?chuck;
assert (await c3.getOwner(#nft "alien51")) == ?alice;
