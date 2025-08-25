"""Test package marker.

Subpackages intentionally omit ``__init__`` files so that their names
don't collide with actual application modules (for example ``accounts``
and ``payments``).  Keeping the subdirectories as namespace packages
allows ``pytest`` to collect tests without importing them as top-level
modules from the project.
"""
