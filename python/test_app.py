import unittest
from unittest.mock import patch, MagicMock
from flask import json
from app import app, get_eth_balance, init_web3, INFRA_API_KEY_ENV_VAL

 # Address from: https://docs.infura.io/api/networks/ethereum/json-rpc-methods/eth_getbalance
valid_ether_address = "0xc94770007dda54cF92009BFF0dE90c06F603a09f"

class TestEthereumAPI(unittest.TestCase):
    @patch.dict('os.environ', {INFRA_API_KEY_ENV_VAL: 'mock_api_key'})
    @patch('app.Web3')
    def setUp(self, mock_web3_class):
        # Set up Flask test client and mock web3 connection
        self.app = app.test_client()
        self.app.testing = True

        # Initialize mock web3
        self.mock_web3 = mock_web3_class.return_value
        self.mock_web3.is_address.return_value = True
        self.mock_web3.eth.get_balance.return_value = 1000000000000000000  # 1 Ether in Wei

    @patch.dict('os.environ', {INFRA_API_KEY_ENV_VAL: 'mock_api_key'})
    @patch('app.Web3')
    def test_init_web3_with_api_key(self, mock_web3_class):
        # Test init_web3 with API key present
        web3_instance = init_web3()
        self.assertIsNotNone(web3_instance, "Expected init_web3 to return a Web3 instance with a valid API key")

    def test_get_eth_balance_invalid_address(self):
        # Test invalid address handling
        self.mock_web3.is_address.return_value = False
        balance, error = get_eth_balance("invalid_address")
        self.assertIsNone(balance)
        self.assertEqual(error, "Error - invalid address")

    def test_get_eth_balance_valid_address(self):
        # Test valid address balance retrieval
        balance, error = get_eth_balance(valid_ether_address)
        self.assertGreater(balance, 0)  # Expecting non-negative value
        self.assertIsNone(error)

    @patch('app.get_eth_balance')
    def test_balance_route_valid_address(self, mock_get_balance):
        # Test /balance/<address> route with a valid address
        mock_get_balance.return_value = (1, None)  # 1 Ether
        response = self.app.get('/balance/'+valid_ether_address)
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertGreater(data['balance'], '0')

    @patch('app.get_eth_balance')
    def test_balance_route_invalid_address(self, mock_get_balance):
        # Test /balance/<address> route with an invalid address
        mock_get_balance.return_value = (None, "Error - invalid address")
        response = self.app.get('/balance/invalid_address')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['balance'], "Error - invalid address")

    @patch('app.get_eth_balance')
    def test_balances_route_multiple_addresses(self, mock_get_balance):
        # Mock balance responses for multiple addresses
        mock_get_balance.side_effect = [
            (1, None),    # 1 Ether for first address
            (None, "Error - invalid address")  # Error for second address
        ]
        
        response = self.app.get('/balances?address='+valid_ether_address+'&address=invalid_address')
        data = json.loads(response.data)
        
        self.assertEqual(response.status_code, 200)
        self.assertGreater(data[valid_ether_address], '0')
        self.assertEqual(data['invalid_address'], "Error - invalid address")

    def test_balances_route_no_addresses(self):
        # Test /balances route without addresses (expecting error)
        response = self.app.get('/balances')
        data = json.loads(response.data)

        self.assertEqual(response.status_code, 400)
        self.assertEqual(data['error'], "At least one Ethereum address is required")

    def test_hello_world_route(self):
        # Test the root endpoint for a simple response
        response = self.app.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.decode(), "Hello, world!")
    
    @patch('app.web3')
    def test_healthz_healthy(self, mock_web3):
        # Mock web3 to simulate a healthy connection
        mock_web3.isConnected.return_value = True

        # Call the healthz endpoint
        response = self.app.get('/healthz')

        # Verify response
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json, {"status": "healthy"})

    @patch('app.web3')
    def test_healthz_unhealthy(self, mock_web3):
        # Mock web3 to simulate an unhealthy connection
        mock_web3.isConnected.return_value = False

        # Call the healthz endpoint
        response = self.app.get('/healthz')

        # Verify response
        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.json, {"status": "unhealthy", "error": "Unable to connect to Ethereum network"})

if __name__ == '__main__':
    unittest.main()
