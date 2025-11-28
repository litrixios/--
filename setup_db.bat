@echo off
:: ============================================================
:: SmartEnergyDB Deployment Tool (Updated with Triggers)
:: ============================================================

echo.
echo ==========================================================
echo       SmartEnergyDB Deployment Tool v2.0
echo ==========================================================
echo.

:: 1. 设置数据库连接信息
echo Please enter Server Name.
echo Default is [localhost]. If you use Express version, try [.\SQLEXPRESS]
set /p ServerName=Server Name (Enter for localhost):
if "%ServerName%"=="" set ServerName=localhost

echo.
echo [1/5] Initializing Database (Drop and Create)...
sqlcmd -S %ServerName% -E -i "sql\00_Init\01_CreateDatabase.sql"
if %errorlevel% neq 0 goto Error

echo.
echo [2/5] Creating Tables...
for %%f in (sql\01_Tables\*.sql) do (
    echo    - Executing: %%f
    sqlcmd -S %ServerName% -E -d SmartEnergyDB -i "%%f"
    if %errorlevel% neq 0 goto Error
)

echo.
echo [3/5] Creating Views and Procedures...
if exist "sql\02_Views_Procs" (
    for %%f in (sql\02_Views_Procs\*.sql) do (
        echo    - Executing: %%f
        sqlcmd -S %ServerName% -E -d SmartEnergyDB -i "%%f"
    )
)

echo.
echo [4/5] Creating Triggers...
:: 这里是新增的步骤
if exist "sql\03_Triggers" (
    for %%f in (sql\03_Triggers\*.sql) do (
        echo    - Executing: %%f
        sqlcmd -S %ServerName% -E -d SmartEnergyDB -i "%%f"
    )
)

echo.
echo [5/5] Importing Seed Data...
:: 注意：这里路径改成了 04_SeedData
if exist "sql\04_SeedData" (
    for %%f in (sql\04_SeedData\*.sql) do (
        echo    - Executing: %%f
        sqlcmd -S %ServerName% -E -d SmartEnergyDB -i "%%f"
    )
)

echo.
echo ==========================================================
echo    Success! Database deployed.
echo ==========================================================
pause
exit

:Error
echo.
echo [ERROR] Script Failed!
pause