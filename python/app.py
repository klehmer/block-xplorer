from flask import Flask, request, jsonify
from web3 import Web3
import os

app = Flask(__name__)

# Set up a connection to the Ethereum network (using Infura or other provider)
BASE_INFURA_URL = "https://mainnet.infura.io/v3/"
INFRA_API_KEY_ENV_VAL = 'INFURA_API_KEY'

def init_web3():
    if INFRA_API_KEY_ENV_VAL not in os.environ:
        print("ERROR: No Infura API key present in environment")
        return None
    api_key = os.getenv(INFRA_API_KEY_ENV_VAL)
    infra_url = BASE_INFURA_URL+api_key

    return Web3(Web3.HTTPProvider(infra_url))

web3 = init_web3()

# Function to get balance of an Ethereum address
def get_eth_balance(address):
    # Check if the address is valid
    if not web3.is_address(address):
        return None, "Error - invalid address"

    # Get the balance in Wei and convert it to Ether
    try:
        balance_wei = web3.eth.get_balance(address)
        balance_eth = web3.from_wei(balance_wei, 'ether')
        return balance_eth, None
    except Exception as e:
        return None, f"Error - {str(e)}"

# retrieve a single balance using path parameter
@app.route('/balance/<address>', methods=['GET'])
def balance(address):
    # Fetch balance
    balance, error = get_eth_balance(address)
    if error:
        return jsonify({"balance": error}), 400

    # Return the balance as a JSON response
    return jsonify({"balance": str(balance)})

# retrieve one or more balances using query parameter
@app.route('/balances', methods=['GET'])
def balances():
    # Get Ethereum addresses from the query parameters
    addresses = request.args.getlist('address')
    if not addresses:
        return jsonify({"error": "At least one Ethereum address is required"}), 400

    balances = {}
    for address in addresses:
        balance, error = get_eth_balance(address)
        if error:
            balances[address] = error
        else:
            balances[address] = str(balance)

    # Return the balances as a JSON response
    return jsonify(balances)

@app.route('/')
def hello_world():
    return "Hello, beautiful world!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001)
