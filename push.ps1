# 一键推送到 GitHub（PowerShell）
#
# 用法（在本文件夹里打开 PowerShell）：
#   .\push.ps1 -RepoUrl https://github.com/<你的用户名>/<仓库名>.git
#
# 前提：装了 Git（没有的话先跑一次： winget install --id Git.Git -e --source winget ）
# 首次 push 会弹出 GitHub 登录窗口（浏览器里点一下授权即可）。

param(
  [Parameter(Mandatory = $true)]
  [string]$RepoUrl,

  [string]$Branch = "main",
  [string]$CommitMessage = "add: 克苏鲁神话星图 (72 实体 / 96 关系)"
)

$ErrorActionPreference = "Stop"

function Find-Git {
  $cmd = Get-Command git -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $cands = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe"
  )
  foreach ($c in $cands) { if (Test-Path $c) { return $c } }
  return $null
}

$git = Find-Git
if (-not $git) {
  Write-Host "没有找到 Git。先装：" -ForegroundColor Yellow
  Write-Host "  winget install --id Git.Git -e --source winget" -ForegroundColor Cyan
  Write-Host "装完关掉重开 PowerShell，再跑这个脚本。" -ForegroundColor Yellow
  exit 1
}

Write-Host "Git: $git" -ForegroundColor DarkGray

if (-not (Test-Path ".git")) {
  & $git init -b $Branch | Out-Null
  Write-Host "已初始化仓库（分支 $Branch）" -ForegroundColor Green
}

# 没配置过身份就写一个本地占位，之后可以去 GitHub 设置里改
$name = (& $git config user.name) 2>$null
if (-not $name) { & $git config user.name "cthulhu-starmap"; Write-Host "设置本地 user.name" -ForegroundColor DarkGray }
$email = (& $git config user.email) 2>$null
if (-not $email) { & $git config user.email "cthulhu-starmap@users.noreply.github.com"; Write-Host "设置本地 user.email" -ForegroundColor DarkGray }

& $git add -A
& $git commit -m $CommitMessage 2>&1 | Out-Host

$hasRemote = (& $git remote) 2>$null
if ($hasRemote -notcontains "origin") {
  & $git remote add origin $RepoUrl
  Write-Host "已添加 origin → $RepoUrl" -ForegroundColor Green
} else {
  & $git remote set-url origin $RepoUrl
  Write-Host "已更新 origin → $RepoUrl" -ForegroundColor Green
}

Write-Host "`n推送中……首次会弹出浏览器登录 GitHub。" -ForegroundColor Cyan
& $git push -u origin $Branch

if ($LASTEXITCODE -eq 0) {
  Write-Host "`n推送成功。" -ForegroundColor Green
  Write-Host "想让它变成可访问的网址：仓库 Settings → Pages → Source 选 Deploy from a branch → main / (root)" -ForegroundColor Yellow
  Write-Host "几分钟后地址是： https://<你的用户名>.github.io/<仓库名>/" -ForegroundColor Yellow
} else {
  Write-Host "`n推送失败，看上面的报错。常见原因：仓库名写错 / 没有权限 / 远端已有内容需要先 pull。" -ForegroundColor Red
  exit 1
}
