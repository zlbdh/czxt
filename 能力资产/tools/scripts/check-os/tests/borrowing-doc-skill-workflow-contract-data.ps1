$ErrorActionPreference = 'Stop'

$script:BorrowingSkillRootModeRows = @(
  @('project', '接入 / 评估 / 落地 / 审计', '仅 project 可写'),
  @('template', '仅离线只读 P4t 审计', '禁止写入'),
  @('unknown / conflict', '无', '所有模式零写入硬失败')
)
$script:BorrowingSkillAccessRootModeLine = '接入仍仅允许 RootMode=project；template、unknown、conflict 必须前置拒绝。'

$script:BorrowingCloseTransactionRows = @(
  @('1', '保留原活动卡字节', '对外仍为原活动状态'),
  @(
    '2', '构造 closed 候选',
    '状态与历史写为 closed；closure_seal_sha256 为空'
  ),
  @(
    '3', '以 no-overwrite 装入候选并调用 seal-borrowing-item.ps1',
    'seal helper 失败不得宣称 closed；不得覆盖后来对象'
  ),
  @('4', '运行根 P4t', 'exit 0 仅进入终锁复核；不得输出 closed'),
  @(
    '5', '持终锁复核并清理 staging',
    '身份、长度、sealed 字节稳定；删除两份 owned 内容后进入 content-deleted 不可逆完成点；目录清理成功才输出 closed'
  ),
  @(
    '可证明失败',
    'ownership 可证明且尚未进入 content-deleted 时恢复原活动卡；失败候选保留到被忽略 staging',
    '显式报告失败阶段与规范化路径；不得宣称 closed'
  ),
  @(
    '所有权不明或不可逆',
    'seal-ownership-unproven 保留当前正式卡与 staging；content-deleted 后不回滚正式卡',
    '保留可审计残留并显式失败；禁止覆盖或猜测恢复'
  )
)
$script:BorrowingCloseScopeLine = '该事务同时适用于 adopt/adapt 与 reject；只有仍能证明正式对象由本事务拥有且尚未进入 content-deleted 才回滚；seal-ownership-unproven 或不可逆后的失败保留证据且不回滚正式卡。'
$script:BorrowingTerminalStateLines = @(
  '同状态追加证据仅限活动状态。',
  'closed/cancelled 为终态且不可修改；后续变化必须新建 supersedes。'
)
