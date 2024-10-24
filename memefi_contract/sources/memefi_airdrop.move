// module memefi::memefi_airdrop {
//     use sui::coin::{Self, Coin};
//     use memefi::memefi_coin::{ MEMEFI_COIN };
//     use sui::balance::{Self, Balance};

//     const E_NOT_ADMIN: u64 = 0;
//     const E_ALREADY_AIRDROPPED: u64 = 1;
//     const E_INSUFFICIENT_BALANCE: u64 = 2;

//     public struct Airdrop has key, store {
//         id: UID,
//         airdropped_users: vector<u64>,
//         admin: address,
//         fee_recipient: address,
//         balance: Balance<MEMEFI_COIN>
//     }

//     fun init(ctx: &mut TxContext) {
//         let admin_addr = ctx.sender();
//         let fee_recipient = ctx.sender();

//         let airdrop = Airdrop {
//             id: object::new(ctx),
//             airdropped_users: vector::empty(),
//             admin: admin_addr,
//             fee_recipient: fee_recipient,
//             balance: balance::zero()
//         };
//         transfer::transfer(airdrop, admin_addr)
//     }

//     public fun is_airdropped(airdrop: &Airdrop, user: u64): bool {
//         vector::contains(&airdrop.airdropped_users, &user)
//     }

//     fun add_to_airdropped(airdrop: &mut Airdrop, user: u64) {
//         vector::push_back(&mut airdrop.airdropped_users, user);
//     }

//     public entry fun fund_airdrop(
//         airdrop: &mut Airdrop,
//         payment: Coin<MEMEFI_COIN>,
//         ctx: &mut TxContext
//     ) {
//         let sender = ctx.sender();
//         if (sender != airdrop.admin) {
//             abort E_NOT_ADMIN
//         };
//         coin::put(&mut airdrop.balance, payment);
//     }

//     public entry fun airdrop(
//         airdrop: &mut Airdrop,
//         recipient: address,
//         user_id: u64,
//         memefi_amount: u64,
//         fee_amount: u64,
//         ctx: &mut TxContext
//     ) {
//         let sender = ctx.sender();
//         if (sender != airdrop.admin) {
//             abort E_NOT_ADMIN
//         };

//         if (is_airdropped(airdrop, user_id)) {
//             abort E_ALREADY_AIRDROPPED
//         };

//         add_to_airdropped(airdrop, user_id);

//         let total_memefi_needed = memefi_amount + fee_amount;

//         let current_balance = balance::value(&airdrop.balance);
//         if (current_balance < total_memefi_needed) {
//             abort E_INSUFFICIENT_BALANCE
//         };

//         let split_amount1 = balance::split(&mut airdrop.balance, memefi_amount);
//         transfer::public_transfer(
//             coin::from_balance(split_amount1, ctx),
//             recipient
//         );

//         let split_amount2 = balance::split(&mut airdrop.balance, fee_amount);
//         transfer::public_transfer(
//             coin::from_balance(split_amount2, ctx),
//             airdrop.fee_recipient
//         );
//     }

// }
