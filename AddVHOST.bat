@echo off

IF ("%1") == ("") (
	goto PARA_MSG
) ELSE IF ("%2") == ("") (
	goto PARA_MSG
) ELSE IF ("%3") == ("") (
	goto PARA_MSG
) ELSE IF ("%4") == ("") (
	goto PARA_MSG
) ELSE (
	SET FILEPATH_HOSTS=%~1
	SET FILEPATH_APACHE=%~2\apache\conf\extra\httpd-vhosts.conf
	SET DIRPATH_VHOSTS=%~3/
	SET SERVICE_NAME=%~4

	goto ADMIN_CHECK
)

:PARA_MSG
color 3
@title Error: Parameters not found...
echo ##
echo ## You have to set all parameters in the start component
echo ##
echo ##########################################################
echo                                                         ##
echo 1 = Hosts.dat in your windows path                      ##
echo 2 = Your xampp folder                                   ##
echo 3 = Your vhost folder                                   ##
echo 4 = Service name of apache (e.g.: Apache2.4)            ##
echo 5 = Port support activated (optional)                   ##
echo 6 = Extended server alias with given ending (optional)  ##
echo                                                         ##
echo ##########################################################
goto exit

:ADMIN_CHECK
@title Loading...
color 5

:: GET EXT ALIAS
SET ALIAS_EXT="false"

IF NOT (%6) == ("") (
	SET ALIAS_EXT=%~6
)

echo Loading...

net session >nul 2>&1
IF NOT %errorLevel% == 0 (
	goto noadmin
) ELSE (
	goto USERSELECT
)

:NOADMIN
@title Open as admin again
cls
color 4
echo Please open this file as ADMIN to continue...
goto exit

:USERSELECT
@title Your choice? /by Davide Perozzi
cls
color 2
echo ##
echo ## What would you like to do?
echo ##
echo ##########################################################
echo                                                         ##
echo  0 = Clone a git repository and #1                      ##
echo  1 = Add a new vhost and restart Apache                 ##
echo  2 = Add a new vhost without restarting Apache          ##
echo  3 = Restart Apache                                     ##
echo  4 = Edit vhosts manually                               ##
echo  5 = Edit hosts manually                                ##
echo                                                         ##
echo  x = Exit                                               ##
echo                                                         ##
echo ------------------------------------------------------- ##
echo                                                         ##
tasklist /FI "IMAGENAME eq httpd.exe" 2>NUL | find /I /N "httpd.exe">NUL
IF "%ERRORLEVEL%"=="0" (
echo  Apache is running                                      ##
) ELSE (
color 8
echo  Apache is NOT running                                  ##
)
echo                                                         ##
echo ------------------------------------------------------- ##
echo                                                         ##
echo  Type in your choice and press [ENTER]                  ##
echo                                                         ##
echo ##########################################################


SET /p OPTION=

IF %OPTION% == 0 (
	goto GETREP
) ELSE IF %OPTION% == 1 (
	goto NEWHOST
) ELSE IF %OPTION% == 2 (
	goto NEWHOST
) ELSE IF %OPTION% == 3 (
	goto RESTART_APACHE
) ELSE IF %OPTION% == 4 (
	goto EDIT_VHOSTS
) ELSE IF %OPTION% == 5 (
	goto EDIT_HOSTS
) ELSE IF %OPTION% == x (
	exit
) ELSE (
	goto USERSELECT
)

:GETREP
@title Select a repository
cls
color 5
echo Enter the url of your repository:
SET /p REPOSITORY=
cls
echo Enter the name of the repository:
SET /p HOSTNAME=
goto CLONEREP

:CLONEREP
cls
color 6
echo Checking out Repository...
echo --------------------------------------------
git clone %REPOSITORY% %DIRPATH_VHOSTS%%HOSTNAME%
echo --------------------------------------------
echo.
IF EXIST %DIRPATH_VHOSTS%%HOSTNAME%/.gitmodules (
echo Init and updating submodules...
echo --------------------------------------------
cd /D %DIRPATH_VHOSTS%%HOSTNAME%
git submodule update --init
echo --------------------------------------------
) ELSE IF EXIST %DIRPATH_VHOSTS%%HOSTNAME%/composer.json (
echo Installing composer components
echo --------------------------------------------
cd /D %DIRPATH_VHOSTS%%HOSTNAME%
composer install
echo --------------------------------------------
)
echo.
IF %ERRORLEVEL% == 0 (
color 2
echo ######################################
echo                                      #
echo Repository successfully checked out  #
echo                                      #
echo ######################################
) ELSE (
	@title ERROR
	color 4
	echo Something went wrong!
)
echo.
echo Press any key to continue...
PAUSE > NUL
goto NEWHOST

:EDIT_VHOSTS
@title Edit: %FILEPATH_APACHE%
notepad %FILEPATH_APACHE%
cls
echo Restart apache now? (y/n)
SET /p RESTART_APACHE_EDIT=

IF "%RESTART_APACHE_EDIT%"=="y" (
	cls
	goto RESTART_APACHE
) ELSE IF "%RESTART_APACHE_EDIT%"=="Y" (
	cls
	goto RESTART_APACHE
) ELSE (
	goto USERSELECT
)


:EDIT_HOSTS
@title Edit: %FILEPATH_HOSTS%
notepad %FILEPATH_HOSTS%
goto USERSELECT

:NEWHOST
cls
@title Register a new vhost
color 5
IF "%HOSTNAME%"=="" (
	echo Enter the name of the host:
	SET /p HOSTNAME=
)

IF EXIST %DIRPATH_VHOSTS%%HOSTNAME%/htdocs/ (
	SET SUBDIR=htdocs
) ELSE IF EXIST %DIRPATH_VHOSTS%%HOSTNAME%/Web/ (
	SET SUBDIR=Web
) ELSE IF EXIST %DIRPATH_VHOSTS%%HOSTNAME%/public/ (
	SET SUBDIR=public
)

IF "%SUBDIR%"=="" (
	echo Subdirectory (relative from root, e.g. htdocs or leave empty^)
	SET /p SUBDIR=
)

IF (%5) == ("") (
	SET PORTACTIVE=false
) ELSE IF (%5)==("true") (
	SET PORTACTIVE=true
) ELSE (
	SET PORTACTIVE=false
)

IF "%PORTACTIVE%"=="true" (
	IF "%PORT%"=="" (
		echo Which port do you want to use? (or leave empty)
		SET /p PORT=
	)
)

IF NOT "%PORT%"=="" (
	SET PORTACTIVE=y
) ELSE (
	SET PORTACTIVE=n
)

IF "%SUBDIR%"=="" (
	SET "SUBDIRPATH="
) ELSE (
	IF NOT "%SUBDIR:~0,1%"=="/" (
		SET SUBDIRPATH=/%SUBDIR%
	) ELSE (
		SET SUBDIRPATH=%SUBDIR%
	)
)

cls

:: Write the vhost configuration options

echo ##
echo. >> %FILEPATH_HOSTS%
echo #vHost: %HOSTNAME% ^ >> %FILEPATH_HOSTS%
echo 127.0.0.1 %HOSTNAME%.local^ >> %FILEPATH_HOSTS%
echo 127.0.0.1 www.%HOSTNAME%.local^ >> %FILEPATH_HOSTS%

echo ## Written in %FILEPATH_HOSTS%

echo. >> %FILEPATH_APACHE%
echo. >> %FILEPATH_APACHE%
echo ^# %HOSTNAME% >> %FILEPATH_APACHE%
echo ^<VirtualHost *:80^>^ >> %FILEPATH_APACHE%
echo    DocumentRoot %DIRPATH_VHOSTS%%HOSTNAME%%SUBDIRPATH%^ >> %FILEPATH_APACHE%
echo    ServerName %HOSTNAME%.local^ >> %FILEPATH_APACHE%
echo    ServerAlias www.%HOSTNAME%.local^ >> %FILEPATH_APACHE%
echo    SetEnv APPLICATION_ENV development >> %FILEPATH_APACHE%

IF NOT "%ALIAS_EXT%"=="false" (
	IF NOT "%ALIAS_EXT%"=="" (
		echo    ServerAlias www.%HOSTNAME%.%ALIAS_EXT% >> %FILEPATH_APACHE%
		echo    ServerAlias %HOSTNAME%.%ALIAS_EXT% >> %FILEPATH_APACHE%
	)
)

echo ^</VirtualHost^>^ >> %FILEPATH_APACHE%

IF %PORTACTIVE%==y (
	echo ^Listen %PORT% >> %FILEPATH_APACHE%
	echo ^<VirtualHost *:%PORT%^>^ >> %FILEPATH_APACHE%
	echo      DocumentRoot %DIRPATH_VHOSTS%%HOSTNAME%%SUBDIRPATH%^ >> %FILEPATH_APACHE%
	echo ^</VirtualHost^>^ >> %FILEPATH_APACHE%
)

echo ## Written in %FILEPATH_APACHE%
echo ##

:: Reset vars after the options were written
SET "HOSTNAME="
SET "PORT="

IF %OPTION% == 1 (
	goto RESTART_APACHE
) ELSE IF %OPTION% == 0 (
	goto RESTART_APACHE
) ELSE (
	goto SUCCESS_MSG
)


:SUCCESS_MSG
@title New vhosts registered
IF %ERRORLEVEL%==0 (
	color 2
	echo ###################################################
	echo                                                  ##
	IF %OPTION% == 2 (
	echo Restart apache and the vhost will be available   ##
	) ELSE (
	echo The new vhost is now available                   ##
	)
	echo                                                  ##
	echo ###################################################
	echo.
) ELSE (
	@title ERROR
	color 4
	echo.
	echo Something went wrong!
	echo.
)
echo Press a [RANDOM] key to continue
PAUSE > NUL
goto USERSELECT

:RESTART_APACHE
@title Restarting apache service (%SERVICE_NAME%)
color 5
IF %OPTION% == 3 (
cls
) ELSE (
echo ---------------------------------
)
echo Stopping service %SERVICE_NAME%
NET STOP %SERVICE_NAME%
echo ---------------------------------
echo Starting service %SERVICE_NAME%
NET START %SERVICE_NAME%

IF NOT %OPTION% == 3 (
	goto SUCCESS_MSG
) ELSE (
	IF NOT %ERRORLEVEL% == 0 (
		color 4
	) ELSE (
		color 2
	)
	echo Press a [RANDOM] key to continue
	PAUSE > NUL
	goto USERSELECT
)

:EXIT
@title Press a random key to exit
echo --------------------------------
echo Press a [RANDOM] key to exit
PAUSE > NUL
exit
