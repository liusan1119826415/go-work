@echo off
REM MetaNode 质押系统启动脚本 (Windows)

echo === MetaNode 质押系统启动脚本 ===

REM 检查是否在正确的目录
if not exist "package.json" (
  echo 错误: 请在项目根目录运行此脚本
  pause
  exit /b 1
)

REM 安装后端依赖
echo 1. 安装后端依赖...
npm install

REM 编译合约
echo 2. 编译智能合约...
npx hardhat compile

REM 安装前端依赖
echo 3. 安装前端依赖...
cd frontend
npm install
cd ..

echo === 安装完成 ===
echo.
echo 要启动开发环境，请执行以下步骤：
echo.
echo 1. 启动后端测试网络：
echo    npx hardhat node
echo.
echo 2. 在新终端中部署合约：
echo    npx hardhat run scripts/deploy.js --network localhost
echo.
echo 3. 启动前端开发服务器：
echo    cd frontend
echo    npm run dev
echo.
echo 4. 在浏览器中访问 http://localhost:3000
echo.
pause