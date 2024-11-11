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
echo -e "${BOLD_BLUE}Prompting for seed phrases and private keys${NC}"
echo
read -p "Enter your seed phrases (in JSON format): " seed_phrases
read -p "Enter your private keys (in JSON format): " private_keys

echo -e "${BOLD_BLUE}Creating the Node.js script file for Frontier v1 network${NC}"
echo
cat << EOF > frontierBatchTx.js
const {
  Connection,
  PublicKey,
  LAMPORTS_PER_SOL,
  Transaction,
  SystemProgram,
  sendAndConfirmTransaction,
  Keypair,
} = require('@solana/web3.js')
const bip39 = require('bip39')
const { derivePath } = require('ed25519-hd-key')
const bs58 = require('bs58')
require('dotenv').config()

const connection = new Connection('https://api.testnet.v1.sonic.game', 'confirmed')

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

async function sendSol(fromKeypair, toPublicKey, amount) {
  const transaction = new Transaction().add(
    SystemProgram.transfer({
      fromPubkey: fromKeypair.publicKey,
      toPubkey: toPublicKey,
      lamports: amount * LAMPORTS_PER_SOL,
    })
  )

  const signature = await sendAndConfirmTransaction(connection, transaction, [fromKeypair])
  console.log('Transaction confirmed with signature:', signature)
}

function generateRandomAddresses(count) {
  const addresses = []
  for (let i = 0; i < count; i++) {
    const keypair = Keypair.generate()
    addresses.push(keypair.publicKey.toString())
  }
  return addresses
}

async function getKeypairFromSeed(seedPhrase) {
  const seed = await bip39.mnemonicToSeed(seedPhrase)
  const derivedSeed = derivePath("m/44'/501'/0'/0'", seed.toString('hex')).key
  return Keypair.fromSeed(derivedSeed.slice(0, 32))
}

function getKeypairFromPrivateKey(privateKey) {
  const decoded = bs58.decode(privateKey)
  return Keypair.fromSecretKey(decoded)
}

function parseEnvArray(envVar) {
  try {
    return JSON.parse(envVar)
  } catch (e) {
    console.error('Failed to parse environment variable:', envVar, e)
    return []
  }
}

;(async () => {
  const seedPhrases = parseEnvArray(process.env.SEED_PHRASES)
  const privateKeys = parseEnvArray(process.env.PRIVATE_KEYS)

  const keypairs = []

  for (const seedPhrase of seedPhrases) {
    keypairs.push(await getKeypairFromSeed(seedPhrase))
  }

  for (const privateKey of privateKeys) {
    keypairs.push(getKeypairFromPrivateKey(privateKey))
  }

  if (keypairs.length === 0) {
    throw new Error('No valid SEED_PHRASES or PRIVATE_KEYS found in the .env file')
  }

  const randomAddresses = generateRandomAddresses(100)
  console.log('Generated 100 random addresses:', randomAddresses)

  const amountToSend = 0.001
  let currentKeypairIndex = 0

  for (const address of randomAddresses) {
    const toPublicKey = new PublicKey(address)
    try {
      await sendSol(keypairs[currentKeypairIndex], toPublicKey, amountToSend)
      console.log(\`Successfully sent \${amountToSend} SOL to \${address}\`)
    } catch (error) {
      console.error(\`Failed to send SOL to \${address}:\`, error)
    }

    await sleep(3000)

    currentKeypairIndex = (currentKeypairIndex + 1) % keypairs.length
  }
})();
EOF

echo
echo -e "${BOLD_BLUE}Setting up environment variables${NC}"
echo
cat << EOT > .env
SEED_PHRASES=$seed_phrases
PRIVATE_KEYS=$private_keys
EOT

echo
echo -e "${BOLD_BLUE}Executing the Node.js script${NC}"
echo
node frontierBatchTx.js
echo
