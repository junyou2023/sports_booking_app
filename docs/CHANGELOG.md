# Changelog

## Unreleased
- 新增分页版商家订单列表 `/merchant/bookings/paged/`；旧端点 `/merchant/bookings/` 保持兼容。
- Facilities: support `near` (lat,lng) + optional `radius` (m) for distance search; results include `distance_m` when used. Activities optionally accept the same parameters while `nearby=1` takes precedence.
