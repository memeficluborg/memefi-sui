module memefi::memefi_coin;

use sui::coin;
use sui::pay;

/// The total supply of `MEMEFI` coins.
const TOTAL_SUPPLY_MEMEFI: u64 = 10_000_000_000;

/// Name of the coin
public struct MEMEFI_COIN has drop {}

fun init(otw: MEMEFI_COIN, ctx: &mut TxContext) {
    // Create the `MEMEFI` supply
    let (mut treasury, metadata) = coin::create_currency(
        otw,
        9,
        b"MEMEFI_COIN",
        b"Memefi Coin",
        b"https://memefi.club",
        option::none(),
        ctx,
    );

    transfer::public_freeze_object(metadata);

    // Mint the total supply of `MEMEFI` tokens.
    let balance = treasury.mint_balance(TOTAL_SUPPLY_MEMEFI);
    let coin = coin::from_balance(balance, ctx);

    // Send all `MEMEFI` tokens to the publisher.
    pay::keep(coin, ctx);

    // Permanently freeze the `TreasuryCap`. Can not be used mutable ever again.
    transfer::public_freeze_object(treasury);
}
