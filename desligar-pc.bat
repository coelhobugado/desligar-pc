@echo off
setlocal enabledelayedexpansion

:: ==========================================
:: CONFIGURAÇÕES INICIAIS E VERIFICAÇÃO DE ADMIN
:: ==========================================
title Gerenciador de Energia Avancado v2.0

:: Verifica permissoes de administrador
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] Este script precisa de privilegios de Administrador.
    echo [!] Solicitando elevacao...
    powershell -Command "Start-Process '%~nx0' -Verb RunAs"
    exit /b
)

:: Definicao de cores (Fundo/Texto)
set "c_padrao=0F"
set "c_destaque=0B"
set "c_alerta=0C"
set "c_sucesso=0A"

:: ==========================================
:: MENU PRINCIPAL
:: ==========================================
:menu
cls
color %c_padrao%
call :header "MENU PRINCIPAL"
echo.
echo  [1] Agendar por TEMPO (ex: em 30 minutos)
echo  [2] Agendar por HORARIO (ex: as 23:00)
echo  [3] Cancelar agendamentos ativos
echo  [4] Sair
echo.
echo -------------------------------------------
set /p "opt=>> Escolha uma opcao: "

if "%opt%"=="1" goto :modo_tempo
if "%opt%"=="2" goto :modo_horario
if "%opt%"=="3" goto :cancelar
if "%opt%"=="4" exit
goto :erro_input

:: ==========================================
:: SELEÇÃO DE AÇÃO (Desligar ou Reiniciar)
:: ==========================================
:selecionar_acao
echo.
echo  O que deseja fazer ao final do tempo?
echo  [S] Desligar (Shutdown)
echo  [R] Reiniciar (Restart)
echo.
set /p "acao_opt=>> Escolha (S/R): "
if /i "%acao_opt%"=="S" (set "flag_cmd=/s" & set "txt_acao=desligado")
if /i "%acao_opt%"=="R" (set "flag_cmd=/r" & set "txt_acao=reiniciado")
if not defined flag_cmd goto :selecionar_acao
goto :eof

:: ==========================================
:: MODO 1: TEMPO (Minutos)
:: ==========================================
:modo_tempo
cls
call :header "AGENDAR POR MINUTOS"
call :selecionar_acao

echo.
echo  Digite os minutos para aguardar (0 para imediato):
set /p "minutos=>> "

:: Validacao numerica via truque de 'set /a'
set /a "teste=%minutos%" 2>nul
if "%minutos%" neq "%teste%" goto :erro_input
if %minutos% lss 0 goto :erro_input

:: Calculo de segundos
set /a segundos=%minutos%*60

:: Executa o comando
call :executar_shutdown %segundos%
goto :menu

:: ==========================================
:: MODO 2: HORARIO ESPECIFICO (PowerShell Backend)
:: ==========================================
:modo_horario
cls
call :header "AGENDAR POR HORARIO"
call :selecionar_acao

echo.
echo  Digite o horario no formato 24h (HH:MM):
echo  Exemplo: 23:30 ou 08:15
set /p "horario=>> "

:: Validacao simples de formato
echo %horario% | findstr /r "^[0-2][0-9]:[0-5][0-9]$" >nul
if %errorlevel% neq 0 (
    echo %horario% | findstr /r "^[0-9]:[0-5][0-9]$" >nul
    if %errorlevel% neq 0 goto :erro_input
)

echo.
echo  [i] Calculando diferenca de tempo...

:: O PowerShell aqui resolve o problema de datas.
:: Se o horario ja passou hoje, ele calcula para o dia seguinte automaticamente.
for /f "usebackq delims=" %%A in (`powershell -Command "$t = Get-Date '%horario%'; if($t -lt (Get-Date)){ $t = $t.AddDays(1) }; [int]($t - (Get-Date)).TotalSeconds"`) do (
    set "segundos_restantes=%%A"
)

if %segundos_restantes% lss 0 (
    echo [!] Erro no calculo do tempo. Tente novamente.
    pause
    goto :menu
)

call :executar_shutdown %segundos_restantes%
goto :menu

:: ==========================================
:: EXECUTAR E FEEDBACK
:: ==========================================
:executar_shutdown
:: %1 = segundos
cls
call :header "CONFIRMACAO"

:: Pega a data/hora exata do desligamento via PowerShell para exibir ao usuario
for /f "usebackq delims=" %%D in (`powershell -Command "(Get-Date).AddSeconds(%1).ToString('dd/MM/yyyy HH:mm:ss')"`) do (
    set "data_final=%%D"
)

color %c_sucesso%
echo.
echo  =============================================
echo   SUCESSO! O computador sera %txt_acao%.
echo  =============================================
echo.
echo   Tempo restante : %1 segundos
echo   Data da acao   : %data_final%
echo.
shutdown %flag_cmd% /t %1 /f
echo  Pressione qualquer tecla para voltar ao menu...
pause >nul
goto :menu

:: ==========================================
:: CANCELAR
:: ==========================================
:cancelar
cls
shutdown /a >nul 2>&1
if %errorlevel% equ 0 (
    color %c_sucesso%
    echo.
    echo  [OK] Agendamento cancelado com sucesso.
) else (
    color %c_alerta%
    echo.
    echo  [!] Nenhum agendamento encontrado para cancelar.
)
pause
goto :menu

:: ==========================================
:: TELAS DE ERRO E HEADER
:: ==========================================
:erro_input
color %c_alerta%
echo.
echo  [ERRO] Entrada invalida. Verifique o formato.
pause
goto :menu

:header
echo.
echo ===========================================
echo   GERENCIADOR DE ENERGIA v2.0
echo   %~1
echo ===========================================
echo.
color %c_padrao%
goto :eof
