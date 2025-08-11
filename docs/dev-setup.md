# Dev Setup Notes

- `.env` files control runtime configuration. When running on Web or desktop,
  `API_BASE_URL` containing `10.0.2.2` is automatically rewritten to
  `127.0.0.1` so the backend on the same machine is reachable.
- Creation pages return with `Navigator.pop(context, true)`; callers should
  `await` the result and refresh their data providers.
- The app uses the `geocoding` package for turning addresses into coordinates.
  Ensure network access and provide location permissions on mobile platforms.
