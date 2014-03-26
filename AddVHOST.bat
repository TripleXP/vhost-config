@echo off

IF (%1) == () (
	goto PARA_MSG
) ELSE IF (%2) == () (
	goto PARA_MSG
) ELSE IF (%3) == () (
	goto PARA_MSG
) ELSE IF (%4) == () (
	goto PARA_MSG
) ELSE (
	SET FILEPATH_HOSTS=%1
	SET FILEPATH_APACHE=%2\apache\conf\extra\httpd-vhosts.conf
	SET DIRPATH_VHOSTS=%3/
	SET SERVICE_NAME=%4

	goto ADMIN_CHECK
)

:PARA_MSG
color 3
@title Error: Parameters not found...
echo ##
echo ## You have to set all parameters in your shortcut...
echo ##
echo ##########################################################
echo                                                         ##
echo 1 = Hosts.dat in yout windows path                      ##
echo 2 = Your xampp folder                                   ##
echo 3 = Your vhost folder                                   ##
echo 4 = Service name of apache (example: Apache2.4)         ##
echo 5 = Extended server alias with given ending (optional)  ##
echo                                                         ##
echo ##########################################################
goto exit

:ADMIN_CHECK
@title Loading...
color 5
:: GET EXT ALIAS
IF (%5%) == () (
	SET ALIAS_EXT=false
) ELSE (
	SET ALIAS_EXT=%5%
)
echo Loading...
net session >nul 2>&1
IF NOT %errorLevel% == 0 (
	@title Open as admin again
	goto noadmin
) ELSE (
	@title Starting...
	color 2
	cls
	echo Starting...
	net start spooler>NUL
	cls
	goto USERSELECT
)

:NOADMIN
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
echo 0 = Add a new vhost and restart Apache                  ##
echo 1 = Add a new vhost without restarting Apache           ##
echo 2 = Restart Apache                                      ##
echo 3 = List vhosts from apache                             ##
echo 4 = Edit vhosts manually                                ##
echo 5 = Edit hosts manually                                 ##
echo x = Exit                                                ##
echo                                                         ##
echo ------------------------------------------------------- ##
echo                                                         ##
echo Type in your choice and press [ENTER]                   ##
echo                                                         ##
echo ##########################################################

SET /p OPTION=

IF %OPTION% == 0 ( 
	goto NEWHOST 
) ELSE IF %OPTION% == 1 (
	goto NEWHOST
) ELSE IF %OPTION% == 2 (
	goto RESTART_APACHE
) ELSE IF %OPTION% == 3 (
	goto LIST_VHOSTS
) ELSE IF %OPTION% == 4 (
	goto EDIT_VHOSTS
) ELSE IF %OPTION% == 5 (
	goto EDIT_HOSTS	
) ELSE IF %OPTION% == x (
	exit
) ELSE (
	goto USERSELECT
)

:EDIT_VHOSTS
@title Edit: %FILEPATH_APACHE%
notepad %FILEPATH_APACHE%
goto USERSELECT

:EDIT_HOSTS
@title Edit: %FILEPATH_HOSTS%
notepad %FILEPATH_HOSTS%
goto USERSELECT

:NEWHOST
cls
@title Register a new vhost
color 5
echo Enter the name of the host:
SET /p HOSTNAME=
echo Is there a subfolder named htdocs? (y/n)
SET /p HTDOCS=
echo Which port do you want to use? (keep empty for no port support)
SET /p PORT=

IF %HTDOCS%==y (
	set HTDOCSACTIVE=/htdocs
) ELSE (
	IF %HTDOCS%==Y (
		set HTDOCSACTIVE=/htdocs
	) ELSE (
		set HTDOCSACTIVE=
	)
)

IF NOT "%PORT%"=="" (
	set PORTACTIVE=y
) ELSE (
	set PORTACTIVE=n
)

cls

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
echo  	DocumentRoot %DIRPATH_VHOSTS%%HOSTNAME%%HTDOCSACTIVE%^ >> %FILEPATH_APACHE% 
echo  	ServerName %HOSTNAME%.local^ >> %FILEPATH_APACHE%
echo  	ServerAlias www.%HOSTNAME%.local^ >> %FILEPATH_APACHE%
IF NOT %ALIAS_EXT% == false (
echo 	ServerAlias www.%HOSTNAME%.%ALIAS_EXT% >> %FILEPATH_APACHE%
echo 	ServerAlias %HOSTNAME%.%ALIAS_EXT% >> %FILEPATH_APACHE%
)
echo ^</VirtualHost^>^ >> %FILEPATH_APACHE%
IF %PORTACTIVE%==y (
	echo ^Listen %PORT% >> %FILEPATH_APACHE%
	echo ^<VirtualHost *:%PORT%^>^ >> %FILEPATH_APACHE%
	echo  	DocumentRoot %DIRPATH_VHOSTS%%HOSTNAME%%HTDOCSACTIVE%^ >> %FILEPATH_APACHE% 	
	echo ^</VirtualHost^>^ >> %FILEPATH_APACHE%
)

echo ## Written in %FILEPATH_APACHE%
echo ##

IF %OPTION% == 1 (
	goto SUCCESS_MSG
) ELSE (
	goto RESTART_APACHE
)


:SUCCESS_MSG
@title New vhosts registered
IF %ERRORLEVEL%==0 (
	color 2
	echo ###################################################
	echo                                                  ##
	IF %OPTION% == 1 (
	echo Restart apache and the vhost will be available   ##
	) ELSE (
	echo The new vhost is now available                   ##  
	)
	echo                                                  ##
	echo ###################################################
) ELSE (
	@title ERROR
	color 4
	echo !!!!!!!!!!!!!!!!!!!!!!!
	echo Something went wrong. !
	echo !!!!!!!!!!!!!!!!!!!!!!!
)
echo Press a [RANDOM] key to continue
PAUSE > NUL
goto USERSELECT


:LIST_VHOSTS
@title The vhosts registered
color 7
cls
type %FILEPATH_APACHE%
echo ---------------------------------
echo Press a [RANDOM] key to continue
PAUSE > NUL
goto :USERSELECT

:RESTART_APACHE
@title Restarting apache service (%SERVICE_NAME%)
color 5
IF %OPTION% == 2 cls
echo ---------------------------------
echo Stopping service %SERVICE_NAME%
NET STOP %SERVICE_NAME%
echo --------------------------------- 
echo Starting service %SERVICE_NAME%
NET START %SERVICE_NAME%   

IF NOT %OPTION% == 2 (
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
