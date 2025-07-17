import sys
import os
import pytest

# Set root to this file's directory
PROJECT_ROOT = os.path.dirname(__file__)

# Add to path so 'src.models' etc. can be imported
sys.path.insert(0, PROJECT_ROOT)

# Point to test location
TEST_PATH = os.path.join(PROJECT_ROOT, 'src')

if not os.path.exists(TEST_PATH):
    raise FileNotFoundError(f"Could not find src/ folder at: {TEST_PATH}")

# Run pytest with coverage
pytest_args = [
    TEST_PATH,
    '--cov=src',
    '--maxfail=1',
    '--disable-warnings',
    '-v'
]

pytest.main(pytest_args)
