from flask import Flask, request, jsonify
from web3 import Web3
import os
import base64

app = Flask(__name__)

# Set up a connection to the Ethereum network (using Infura or other provider)
BASE_INFURA_URL = "https://mainnet.infura.io/v3/"
INFRA_API_KEY_ENV_VAL = 'INFURA_API_KEY'

def init_web3():
    if INFRA_API_KEY_ENV_VAL not in os.environ:
        print("ERROR: No Infura API key present in environment")
        return None
    encoded_api_key = os.getenv(INFRA_API_KEY_ENV_VAL)
    
    try:
        decoded_api_key = base64.b64decode(encoded_api_key).decode('utf-8')
    except Exception as e:
        print("ERROR: could not decode Infura API key: {e}")
        return None
    infra_url = BASE_INFURA_URL+decoded_api_key

    return Web3(Web3.HTTPProvider(infra_url))

web3 = init_web3()

# Function to get balance of an Ethereum address
def get_eth_balance(address):

    # Check if the address is valid
    if not web3.is_address(address):
        return jsonify({"error": "Invalid web3 address"}), 400

    # Get the balance in Wei and convert it to Ether
    balance_wei = web3.eth.get_balance(address)
    balance_eth = web3.from_wei(balance_wei, 'ether')

    return balance_eth

# Define the endpoint
@app.route('/balance', methods=['GET'])
def balance():
    # Get the Ethereum address from the query parameters
    address = request.args.get('address')
    if not address:
        return jsonify({"error": "Ethereum address is required"}), 400

    # Fetch balance
    balance = get_eth_balance(address)
    if balance is None:
        return jsonify({"error": "Invalid Ethereum address"}), 400

    # Return the balance as a JSON response
    return jsonify({"address": address, "balance": str(balance)})

@app.route('/')
def hello_world():
    return "Hello, beautiful world!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
