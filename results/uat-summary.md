| 用例 | 输入 | 期望 | 实际 | 结论 |
| ---- | ---- | ---- | ---- | ---- |
| 搜索活动（Near=0,0,R=10km） | GET /activities?near=0,0&radius=10km | 返回半径内结果且按距离升序 | TODO | TODO |
| 预订并支付成功 | checkout→webhook succeeded | 订单 confirmed，paid=True | TODO | TODO |
| 预订失败释放 | checkout→webhook failed | 若实现则释放占座 | 未实现 | TODO |
| 并发抢最后一席 | 两用户并发 checkout | 仅1成功；库存准确 | TODO | TODO |
