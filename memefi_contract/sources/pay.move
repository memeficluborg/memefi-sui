module memefi::pay;

use sui::coin::{Self, Coin};
use sui::event;
use sui::table::{Self, Table};
use sui::sui::SUI;
use std::string::{String};

// === Constants ===
const FIXED_AMOUNT: u64 = 2_000_000_000; // 2 SUI tokens with 9 decimal places

const FIXED_RECIPIENT: address = @0xb528d75685b950bfe53970b2f3644174b208e3bedd930b883e95482d25510759;

// === Errors ===
const ENonceAlreadyUsed: u64 = 11;
const EInsufficientBalance: u64 = 12;

// [Shared] PaymentRegistry manages payment nonces to prevent duplicate transactions.
public struct PaymentRegistry has key {
    id: UID,
    nonces: Table<u64, bool>,
}

// PaymentEvent is emitted when tokens are successfully paid to the target address.
public struct PaymentEvent has copy, drop {
    payer: address,
    recipient: address,
    amount: u64,
    nonce: u64,
    userId: String,
}

public struct PAY has drop {}

// === Initializer ===

fun init(
    _otw: PAY,
    ctx: &mut TxContext,
) {
    let registry = PaymentRegistry {
        id: object::new(ctx),
        nonces: table::new(ctx),
    };
    transfer::share_object(registry);
}

// === Public Functions ===

public fun pay(
    registry: &mut PaymentRegistry,
    payment: Coin<SUI>,
    nonce: u64,
    userId: String,
    ctx: &mut TxContext,
) {
    let payer = ctx.sender();

    let amount = coin::value(&payment);

    assert!(amount >= FIXED_AMOUNT, EInsufficientBalance);

    assert!(!registry.nonces.contains(nonce), ENonceAlreadyUsed);
    registry.nonces.add(nonce, true);

    transfer::public_transfer(payment, FIXED_RECIPIENT);

    event::emit(PaymentEvent {
        payer,
        recipient: FIXED_RECIPIENT,
        amount: FIXED_AMOUNT,
        nonce,
        userId,
    });
}

// === Accessor ===

public fun is_nonce_used(registry: &PaymentRegistry, nonce: u64): bool {
    registry.nonces.contains(nonce)
}

#[test_only]
public(package) fun test_init(ctx: &mut TxContext): PaymentRegistry {
    let mut registry = PaymentRegistry {
        id: object::new(ctx),
        nonces: table::new(ctx),
        balance: balance::zero(),
        owner: tx_context::sender(ctx),
    };
    init(PAY {}, ctx);
    registry
}