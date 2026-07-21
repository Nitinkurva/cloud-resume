import unittest
from unittest.mock import patch, MagicMock
import json

# Import the lambda_handler function from your lambda_function.py file
from lambda_function import lambda_handler

class TestLambdaFunction(unittest.TestCase):

    @patch('lambda_function.table')  # Intercept the DynamoDB table variable
    def test_lambda_handler_success(self, mock_table):
        # 1. ARRANGE: Set up what the fake DynamoDB response should look like
        mock_table.update_item.return_value = {
            'Attributes': {
                'visitor_count': 10
            }
        }

        # 2. ACT: Run the function with empty event and context arguments
        response = lambda_handler({}, {})

        # 3. ASSERT: Verify the function returned what we expected
        # Check HTTP Status Code
        self.assertEqual(response['statusCode'], 200)

        # Check CORS Headers exist
        self.assertIn('Access-Control-Allow-Origin', response['headers'])
        self.assertEqual(response['headers']['Access-Control-Allow-Origin'], '*')

        # Check the Body contains the correct view count
        body = json.loads(response['body'])
        self.assertEqual(body['count'], 10)

        # Verify DynamoDB update_item was actually called
        mock_table.update_item.assert_called_once()

if __name__ == '__main__':
    unittest.main()