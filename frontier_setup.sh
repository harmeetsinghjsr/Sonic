#!/bin/bash

BOLD_BLUE='\033[1;34m'
NC='\033[0m'
echo
if ! command -v node &> /dev/null
then
    echo -e "${BOLD_BLUE}Node.js is not installed. Installing Node.js...${NC}"
    echo
    curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo -e "${BOLD_BLUE}Node.js is already installed.${NC}"
fi
echo
if ! command -v npm &> /dev/null
then
    echo -e "${BOLD_BLUE}npm is not installed. Installing npm...${NC}"
    echo
    sudo apt-get install -y npm
else
    echo -e "${BOLD_BLUE}npm is already installed.${NC}"
fi
echo
echo -e "${BOLD_BLUE}Creating project directory and navigating into it${NC}"
mkdir -p FrontierBatchTx
cd FrontierBatchTx
echo
echo -e "${BOLD_BLUE}Initializing a new Node.js project${NC}"
echo
npm init -y
echo
echo -e "${BOLD_BLUE}Installing required packages${NC}"
echo
npm install @solana/web3.js bip39 ed25519-hd-key bs58 dotenv
echo

# Prompt for either a seed phrase or a private key
echo -e "${BOLD_BLUE}Enter your Solana wallet details${NC}"
read -p "Enter your seed phrase or private key: " wallet_input

echo -e "${BOLD_BLUE}Creating the Node.js script file for Frontier v1 network${NC}"
echo
cat << EOF > frontierBatchTx.js
import { Connection, PublicKey, LAMPORTS_PER_SOL, Transaction, SystemProgram, sendAndConfirmTransaction, Keypair } from '@solana/web3.js';
import bip39 from 'bip39';
import { derivePath } from 'ed25519-hd-key';
import * as bs58 from 'bs58';
import dotenv from 'dotenv';
dotenv.config();

const connection = new Connection('https://api.testnet.v1.sonic.game', 'confirmed');

// Sleep function to add delay
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Function to send SOL from one account to another
async function sendSol(fromKeypair, toPublicKey, amount) {
  const transaction = new Transaction().add(
    SystemProgram.transfer({
      fromPubkey: fromKeypair.publicKey,
      toPubkey: toPublicKey,
      lamports: amount * LAMPORTS_PER_SOL,
    })
  );

  const signature = await sendAndConfirmTransaction(connection, transaction, [fromKeypair]);
  console.log('Transaction confirmed with signature:', signature);
}

// Generate random addresses for testing
function generateRandomAddresses(count) {
  const addresses = [];
  for (let i = 0; i < count; i++) {
    const keypair = Keypair.generate();
    addresses.push(keypair.publicKey.toString());
  }
  return addresses;
}

// Function to create Keypair from either seed phrase or private key
async function getKeypair() {
  const walletInput = process.env.WALLET_INPUT;

  if (walletInput.split(" ").length > 1) {  // Detects if it's a seed phrase
    const seed = await bip39.mnemonicToSeed(walletInput);
    const derivedSeed = derivePath("m/44'/501'/0'/0'", seed.toString('hex')).key;
    return Keypair.fromSeed(derivedSeed.slice(0, 32));
  } else {  // Assume it's a private key in Base58 format
    const decoded = bs58.decode(walletInput);
    return Keypair.fromSecretKey(decoded);
  }
}

(async () => {
  const keypair = await getKeypair();
  const randomAddresses = generateRandomAddresses(100);
  console.log('Generated 100 random addresses:', randomAddresses);

  const amountToSend = 0.001;

  for (const address of randomAddresses) {
    const toPublicKey = new PublicKey(address);
    try {
      await sendSol(keypair, toPublicKey, amountToSend);
      console.log(\`Successfully sent \${amountToSend} SOL to \${address}\`);
    } catch (error) {
      console.error(\`Failed to send SOL to \${address}:\`, error);
    }

    // Delay of 3 seconds between sending to different addresses
    await sleep(3000);
  }
})();
EOF

echo
echo -e "${BOLD_BLUE}Setting up environment variables${NC}"
echo
cat << EOT > .env
WALLET_INPUT=$wallet_input
EOT

echo
echo -e "${BOLD_BLUE}Executing the Node.js script${NC}"
echo
node frontierBatchTx.js
echo
