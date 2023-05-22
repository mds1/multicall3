# Multicall3 Python Example

The Python Multicall3 example uses [Ape](https://github.com/ApeWorX/ape).

Ape has native Multicall3 support which we leverage here.
This example fetches the balances of 3 tokens for 3 users, along with token symbol and decimals.
It then formats and prints the results.

To run the example:

1. Set an environment variable called `WEB3_INFURA_PROJECT_ID` that contains your Infura project ID.
2. Create a virtual environment with `python3 -m venv venv`
3. Activate the virtual environment with `source venv/bin/activate`
4. Install the dependencies with `pip install -r requirements.txt`
5. Run `python3 main.py`

See the code and comments in `main.py` for more information.
