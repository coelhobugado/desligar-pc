@echo off
setlocal enabledelayedexpansion

:: Título do programa
title Menu de Desligamento

:: Cores
set cor_titulo=4F
set cor_menu=0F
set cor_opcao=0A
set cor_erro=0C

:: Menu principal
:menu
cls
color %cor_titulo%
echo.
echo ===========================================
echo      Menu de Desligamento
echo ===========================================
echo.
color %cor_menu%
echo 1. Desligar em X minutos
echo 2. Desligar em um horario especifico
echo 3. Cancelar desligamento agendado
echo 4. Sair
echo.
color %cor_opcao%
set /p opcao="Escolha uma opcao: "

:: Validação da opção escolhida
if "%opcao%"=="1" (
  call :desligar_minutos
) else if "%opcao%"=="2" (
  call :desligar_horario
) else if "%opcao%"=="3" (
  call :cancelar_desligamento
) else if "%opcao%"=="4" (
  color %cor_menu%
  echo Saindo...
  exit
) else (
  color %cor_erro%
  echo Opcao invalida.
  pause
  goto menu
)

goto menu

:: Desligar em X minutos
:desligar_minutos
cls
color %cor_titulo%
echo.
echo ===========================================
echo      Desligar em X minutos
echo ===========================================
echo.
color %cor_menu%
echo Digite quantos minutos voce deseja esperar para desligar:
set /p minutos=

:: Validação da entrada
set isnum=1
for /f "delims=0123456789" %%i in ("%minutos%") do set isnum=0

if "%isnum%"=="0" (
  color %cor_erro%
  echo Por favor, insira um numero valido.
  pause
  goto desligar_minutos
)

set /a segundos=%minutos%*60
color %cor_menu%
echo Desligando em %minutos% minutos (%segundos% segundos).
shutdown /s /t %segundos%
echo Agendamento realizado.
pause
goto menu

:: Desligar em um horário específico
:desligar_horario
cls
color %cor_titulo%
echo.
echo ===========================================
echo      Desligar em um horario especifico
echo ===========================================
echo.
color %cor_menu%
echo Digite o horario para desligar (HH:MM):
set /p horario=

:: Validação do formato do horário
if not "%horario:~2,1%"==":" (
  color %cor_erro%
  echo Formato de horario invalido.
  pause
  goto desligar_horario
)

:: Cálculo do tempo restante para o horário desejado
for /f "tokens=1-4 delims=/: " %%a in ("%time%") do set hora_atual=%%a& set minuto_atual=%%b
for /f "tokens=1-2 delims=:" %%a in ("%horario%") do set hora_desejada=%%a& set minuto_desejado=%%b

set /a tempo_restante=((hora_desejada*60+minuto_desejado)-(hora_atual*60+minuto_atual))*60

if %tempo_restante% lss 0 (
  set /a tempo_restante=%tempo_restante%+24*60*60
)

color %cor_menu%
echo Desligando as %horario%.
shutdown /s /t %tempo_restante%
echo Agendamento realizado.
pause
goto menu

:: Cancelar desligamento agendado
:cancelar_desligamento
shutdown /a
color %cor_menu%
echo Desligamento agendado cancelado.
pause
goto menu