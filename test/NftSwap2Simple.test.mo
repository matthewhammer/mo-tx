import Principal "mo:base/Principal";
import State "../src/nft_swapper/State";
import { NftCollection } "../src/nft_collection/Main";
import NftSwapper "../src/nft_swapper/Core";

let alice = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
let bob = Principal.fromText("renrk-eyaaa-aaaaa-aaada-cai");
let installer = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

// Two collections, c1 and c2
let c1 = await NftCollection();
let c2 = await NftCollection();

assert await c1.create(#nft "ape42", alice);
assert await c2.create(#nft "baboon13", bob);

let n1 = { id = #nft "ape42"; collection = c1 };
let n2 = { id = #nft "baboon13"; collection = c2 };

let swapper = NftSwapper.Core(installer, State.init(installer));

let thePlan = {
    swap2Reqs = [{
        ownedNft1 = { owner = alice; nft = n1 };
        ownedNft2 = { owner = bob; nft = n2 };
                 }];
};

assert swapper.submitPlan(alice, thePlan);
assert swapper.submitPlan(bob, thePlan);
