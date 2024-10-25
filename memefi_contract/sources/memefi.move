module memefi::memefi;

use memefi::treasury;
use sui::coin;
use sui::pay;
use sui::url;

// === Constants ===
const DECIMALS: u8 = 18;
const SYMBOL: vector<u8> = b"MEMEFI";
const NAME: vector<u8> = b"MEMEFI";
const DESCRIPTION: vector<u8> = b"MEMEFI coin issued by memefi club.";
const ICON_URL: vector<u8> = b"https://memefi.club/image.svg";
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

    transfer::public_share_object(coin_metadata);

    // Mint the total supply of `MEMEFI` tokens.
    let balance = treasury_cap.mint_balance(TOTAL_SUPPLY);
    let coin = coin::from_balance(balance, ctx);
    pay::keep(coin, ctx);

    // Wrap the `TreasuryCap` in a shared object to disallow mutating the token supply.
    let wrapped_treasury = treasury::wrap(treasury_cap, ctx);
    treasury::share(wrapped_treasury);
}
