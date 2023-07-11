import Principal "mo:base/Principal";

import { NftCollection } "../src/nft_collection/Main";
import { NftSwapper } "../src/nft_swapper/Main";

let alice = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
let bob = Principal.fromText("renrk-eyaaa-aaaaa-aaada-cai");
let charles = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

// Two collections, c1 and c2
let c1 = await NftCollection();
let c2 = await NftCollection();

assert await c1.create(#nft "ape1", alice);
assert await c2.create(#nft "ape2", bob);

// Initialize swapper to know about c1 and c2:
let swapper = await NftSwapper(?[c1, c2]);




