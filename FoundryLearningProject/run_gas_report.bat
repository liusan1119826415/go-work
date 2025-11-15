@echo off
echo 正在运行 gas 测试并生成报告...
forge test --gas-report > gas_report.txt
echo Gas 报告已生成到 gas_report.txt 文件中

echo.
echo 正在打开 gas 报告...
type gas_report.txt

echo.
echo 按任意键退出...
pause >nul