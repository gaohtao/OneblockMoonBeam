const Web3 = require('web3');
const { abi } = require('./compile');

/*
   -- Define Provider & Variables --
*/
// Provider
const providerRPC = {
   development: 'http://localhost:9933',
   moonbase: 'https://rpc.api.moonbase.moonbeam.network',
};
const web3 = new Web3(providerRPC.moonbase); //Change to correct network

// Variables
const account_from = {
   privateKey: '5fb92d6e98884f76de468fa3f6278f8807c48bebc13595d45af5bdc4da702133',
};
const contractAddress = '0x0BD1aF205f61b113749B8Df75E624C3010848CF6';

/*
   -- Send Function --
*/
// Create Contract Instance
const contract = new web3.eth.Contract(abi, contractAddress);

// Build Increment Tx
const resetTx = contract.methods.reset();

const reset = async () => {
   console.log(
      `Calling the reset() function in contract at address: ${contractAddress}`
   );

   // Sign Tx with PK
   const createTransaction = await web3.eth.accounts.signTransaction(
      {
         to: contractAddress,
         data: resetTx.encodeABI(),
         gas: await resetTx.estimateGas(),
      },
      account_from.privateKey
   );

   // Send Tx and Wait for Receipt
   const createReceipt = await web3.eth.sendSignedTransaction(
      createTransaction.rawTransaction
   );
   console.log(`Tx successful with hash: ${createReceipt.transactionHash}`);
};

reset();