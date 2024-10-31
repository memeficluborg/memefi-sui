/// This module defines and initializes the `MEMEFI` coin.
/// It creates a fixed total supply and sets up a secure treasury mechanism to ensure the
/// coin's supply remains immutable after the initial minting.
///
/// A total of 10 billion MEMEFI tokens are minted and allocated to the publisher’s
/// address. This ensures that the publisher has full control over the initial
/// distribution of tokens.
///
/// The coin’s metadata are frozen after initialization to prevent any future
/// modifications, establishing the coin's identity as immutable.
///
/// The `TreasuryCap`, which controls minting rights, is wrapped in a shared object and
/// marked as immutable. This prevents any further minting, ensuring that `MEMEFI` remains
/// a fixed-supply token after initialization.
module memefi::memefi;

use memefi::treasury;
use sui::coin;
use sui::pay;
use sui::url;

// === Constants ===
const DECIMALS: u8 = 18;
const SYMBOL: vector<u8> = b"MEMEFI"; // TODO: Finalise symbol
const NAME: vector<u8> = b"MEMEFI"; // TODO: Finalise coin name
const DESCRIPTION: vector<u8> = b"MEMEFI coin issued by memefi club."; // TODO: Finalise description
const ICON_URL: vector<u8> = b"https://memefi.club/image.svg"; // TODO: Update coin image
const TOTAL_SUPPLY: u64 = 10_000_000_000;

/// Name of the coin
public struct MEMEFI has drop {}

#[allow(lint(share_owned))]
fun init(otw: MEMEFI, ctx: &mut TxContext) {
    let (mut treasury_cap, coin_metadata) = coin::create_currency(
        otw,
        DECIMALS,
        SYMBOL,
        NAME,
        DESCRIPTION,
        option::some(url::new_unsafe(ICON_URL.to_ascii_string())),
        ctx,
    );

    // Don't allow future mutations of coin metadata.
    transfer::public_freeze_object(coin_metadata);

    // Mint the total supply of `MEMEFI` tokens.
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ctx);
    pay::keep(coin, ctx);

    // Wrap the `TreasuryCap` in a shared object to disallow mutating the token supply.
    let wrapped_treasury = treasury::wrap(treasury_cap, ctx);
    treasury::share(wrapped_treasury);
}
