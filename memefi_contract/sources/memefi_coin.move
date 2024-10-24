module memefi::memefi_coin;

use sui::coin::{Self, TreasuryCap};

public struct MEMEFI_COIN has drop {}

fun init(witness: MEMEFI_COIN, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
        witness,
        18,
        b"MEMEFI_COIN",
        b"",
        b"https://memefi.club",
        option::none(),
        ctx,
    );
    transfer::public_freeze_object(metadata);
    transfer::public_transfer(treasury, ctx.sender())
}

public fun mint(
    treasury_cap: &mut TreasuryCap<MEMEFI_COIN>,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext,
) {
    let coin = coin::mint(treasury_cap, amount, ctx);
    transfer::public_transfer(coin, recipient)
}
