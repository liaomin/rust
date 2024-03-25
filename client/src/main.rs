use std::str::FromStr;

// use solana_sdk::client;
use solana_sdk::signature::Signer;
use solana_rpc_client::rpc_client;
use solana_sdk::signer::keypair;
use solana_sdk::transaction;
use solana_program::instruction;
use solana_program::pubkey;
// use spl_token::instruction;

const RPC_ADDR: &str = "https://api.devnet.solana.com";

// fn createToken(client:&solana_rpc_client::rpc_client::RpcClient){
    
//     solana_program::g
// }


fn main() {
    let helloworld = pubkey::Pubkey::from_str("8LGzmomr58ZQ4tDvDKz6D77AQ1cmtRJTFwtpqqH6JpMY").unwrap();
    let array: [u8;64] = [212,205,92,185,124,19,207,44,69,89,155,188,243,152,23,183,90,11,229,70,96,227,230,78,201,36,8,20,179,177,92,195,21,87,86,203,22,51,181,198,195,162,53,137,20,49,213,110,158,11,166,98,50,16,20,142,22,177,196,98,129,95,178,75];

    // let me = keypair::Keypair::from_base58_string("5ibdGhFoSocVieRkKhFN4vMpCA5iXdP3QPxWgq5tX8QTBn6W3XN1avaunn8dabtcKcW7wHSt3cNnVq1doDiGfkGB");
    
    let me = keypair::Keypair::from_bytes(&array).unwrap();

    println!("me is {}", me.pubkey());

    let client: rpc_client::RpcClient = rpc_client::RpcClient::new(RPC_ADDR);
    // createToken(&client);

    let account_metas = vec![
        instruction::AccountMeta::new(me.pubkey(), true),
    ];

    let instruction = instruction::Instruction::new_with_bytes(
        helloworld,
        "hello".as_bytes(),
        account_metas,
    );
    let ixs = vec![instruction];

    let latest_blockhash = client.get_latest_blockhash().unwrap();
    let sig = client.send_and_confirm_transaction(&transaction::Transaction::new_signed_with_payer(
        &ixs,
        Some(&me.pubkey()),
        &[&me],
        latest_blockhash,
    ));

    // println!("tx:{}", sig.unwrap_err());
    println!("tx:{}", sig.unwrap());
}