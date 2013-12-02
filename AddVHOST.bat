@echo off

::Configuration 
SET filepath_host=C:\Windows\System32\drivers\etc\hosts
SET filepath_apache=D:\xampp\apache\conf\extra\httpd-vhosts.conf
SET dirpath_vhosts=E:/vhosts/

echo Loading...
net stop spooler>NUL
IF NOT %ERRORLEVEL%==0 (
	goto noadmin
) ELSE (
	cls
	echo Starting...
	net start spooler>NUL
	cls
	goto userselect
)

:NOADMIN
cls
echo Please open this file as ADMIN to continue...
goto exit

:USERSELECT
::Choice
cls
echo #############################################
echo                                            ##
echo vHost configuration (by Davide Perozzi)    ##
echo                                            ##
echo ###############################            ##
echo                              ##            ##
echo What would you like to do?   ##            ##
echo                              ##            ##
echo ##########################################################	
echo                                                         ##
echo 0 = Add a new vhost and restart Apache                  ##
echo 1 = Add a new vhost without restarting Apache           ##
echo 2 = Restart Apache                                      ##
echo 3 = List vhosts from apache                             ##
echo (Type in your choice and press enter)                   ##
echo                                                         ##
echo ##########################################################

SET /p option=

IF %option% == 0 ( 
	goto NEWHOST 
) ELSE IF %option% == 1 (
	goto NEWHOST
) ELSE IF %option% == 2 (
	goto RESTART_APACHE
) ELSE IF %option% == 3 (
	goto LIST_VHOSTS
) ELSE (
	goto USERSELECT
)

:NEWHOST
cls
@title = Add a vHost
echo Enter the name of the host:
SET /p hostname=
echo Is there a subfolder named htdocs? (y/n)
SET /p htdocs=

IF %htdocs%==y (
	set htdocsactive=/htdocs
) ELSE (
	IF %htdocs%==Y (
		set htdocsactive=/htdocs
	) ELSE (
		set htdocsactive=
	)
)

echo ^#vHost: %hostname% ^ >> %filepath_host%
echo 127.0.0.1 %hostname%.local^ >> %filepath_host%
echo 127.0.0.1 www.%hostname%.local^ >> %filepath_host%

echo __Written in hosts.dat...

echo ^<VirtualHost *:80^>^ >> %filepath_apache%
echo  	DocumentRoot %dirpath_vhosts%%hostname%%htdocsactive%^ >> %filepath_apache% 
echo  	ServerName %hostname%.local^ >> %filepath_apache%
echo  	ServerAlias www.%hostname%.local^ >> %filepath_apache%
echo ^</VirtualHost^>^ >> %filepath_apache%

echo __Written in httpd-vhosts.conf...

@title = Add a vHost - Restarting Apache...
IF %option% == 1 goto EXIT
echo ####################################
echo Restarting Apache service...      ##
NET STOP Apache2.4 
echo Restarting...                     ##
NET START Apache2.4               
echo                                   ##
echo ###################################################
echo                                                  ##
echo Your new virtual host is now available.          ##
echo Open it in the browser: http://%hostname%.local  ##
echo                                                  ##
echo ###################################################
goto EXIT

:LIST_VHOSTS
type %filepath_apache%
PAUSE

:RESTART_APACHE
cls
@title = Restarting Apache...
echo ####################################
echo Restarting Apache service...      ##
NET STOP Apache2.4 
echo Restarting...                     ##
NET START Apache2.4               
echo                                   ##
echo ####################################

:EXIT
echo [PRESS A RANDOM KEY TO EXIT]
PAUSE > NUL
