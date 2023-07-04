import Principal "mo:base/Principal";

import { NftCollection } "../src/nft_collection/Main";

let alice = Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
let bob = Principal.fromText("renrk-eyaaa-aaaaa-aaada-cai");
let charles = Principal.fromText("rno2w-sqaaa-aaaaa-aaacq-cai");

let can = await NftCollection();

assert await can.create(#nft "ape1", alice);
assert await can.create(#nft "ape2", bob);

assert (await can.getOwner(#nft "ape1")) == ?alice;
assert (await can.getOwner(#nft "ape2")) == ?bob;

assert await can.installerSend(#nft "ape1", bob);
assert await can.installerSend(#nft "ape2", alice);

assert (await can.getOwner(#nft "ape1")) == ?bob;
assert (await can.getOwner(#nft "ape2")) == ?alice;
