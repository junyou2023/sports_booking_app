# backend/__init__.py
"""
Marks backend as a Python package – **必须要有**，否则 Django
找不到 ‘backend’ 模块（你之前的 ImportError 就是它）。
"""

"""
Marks backend as a Python package so that `import backend` works.
Nothing else is required here.
"""

# backend/tests/conftest.py
import pytest
from rest_framework.test import APIClient

@pytest.fixture
def client():
    return APIClient()
