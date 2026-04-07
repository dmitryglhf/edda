"""Edda - a lightweight vector search engine."""

from ._common import SearchResult
from .flat import IndexFlat

__version__ = "0.1.1"
__all__ = ["IndexFlat", "SearchResult", "__version__"]
