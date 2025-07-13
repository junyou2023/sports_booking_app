"""Backend package initializer.

This file marks the ``backend`` directory as a Python package so that modules
inside can be imported using ``import backend``.
Historically a pytest fixture was defined here, but importing Django-specific
modules at package import time caused ``ModuleNotFoundError`` before the Django
settings were configured. The fixture has been moved to
``backend/tests/conftest.py`` to avoid early imports.
"""
