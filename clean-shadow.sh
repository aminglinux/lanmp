#!/bin/bash

echo "$0 会停掉所有启动中的lamp和lnmp"
while :
do
read -p "Input yes or no (Y|N):" a
if [ $a == y -o $a == Y ]
then
    echo "Ok,continue!"
    break
elif [ $a == N -o $a == n ]
then
    echo "goodbye!"
    exit
else
    echo -e "\033[31m Please,Try again !\033[0m "
    continue
fi
done

if ! rpm -qa |grep "^psmisc"
then 
    yum -y install psmisc
fi

##查看进程是否存在
check_proc (){
line=`ps aux|grep $1|wc -l`
if [ $line -ge 1 ]
then 
 /usr/bin/killall $1
fi
}

##killall name
check_proc mysqld >/dev/null 2>&1
check_proc nginx  >/dev/null 2>&1  
check_proc httpd   >/dev/null 2>&1
check_proc php-fpm  >/dev/null 2>&1




##clean lamp
clean_mysql(){
[ -d /usr/local/mysql ] && /bin/rm -rf /usr/local/mysql  >/dev/null 2>&1
[ -f /etc/init.d/mysqld ] && /bin/rm -rf /etc/init.d/mysqld  >/dev/null 2>&1
[ -f /etc/my.cnf ] && /bin/rm -rf /etc/my.cnf >/dev/null 2>&1
}
clean_apache(){
[ -d /usr/local/apache2 ] && /bin/rm -rf /usr/local/apache2 >/dev/null 2>&1
[ -f /etc/init.d/httpd ] && /bin/rm -rf /etc/init.d/httpd >/dev/null 2>&1
}
clean_php(){
[ -f /usr/local/src/phpphp-5.4.40 ] && /bin/rm -rf /usr/local/src/phpphp-5.4.40 > /dev/null 2>&1
[ -f /usr/local/src/phpphp-5.6.0 ] && /bin/rm -rf /usr/local/src/phpphp-5.6.0 > /dev/null 2>&1
[ -d /usr/local/php ] && /bin/rm -rf /usr/local/php  >/dev/null 2>&1
}


##clean lnmp
clean_nginx(){
[ -d /usr/local/nginx ] && /bin/rm -rf /usr/local/nginx >/dev/null 2>&1
[ -f /etc/init.d/nginx ] && /bin/rm -rf /etc/init.d/nginx >/dev/null 2>&1
}
clean_phpfpm(){
[ -f /usr/local/src/phpphp-5.4.40 ] && /bin/rm -rf /usr/local/src/phpphp-5.4.40 > /dev/null 2>&1
[ -f /usr/local/src/phpphp-5.6.0 ] && /bin/rm -rf /usr/local/src/phpphp-5.6.0 > /dev/null 2>&1
[ -d /usr/local/php-fpm ] && /bin/rm -rf /usr/local/php-fpm >/dev/null 2>&1
[ -f /etc/init.d/php-fpm ] && /bin/rm -rf /etc/init.d/php-fpm >/dev/null 2>&1
}

echo "清除lamp还是lnmp"
select cl in lamp lnmp
do
  case $cl in
     lamp)
      clean_mysql
      clean_apache
      clean_php
      echo -e "\033[32m  clean all \033[0m"
      break
     ;;
     lnmp)
      clean_mysql
      clean_nginx
      clean_phpfpm
     echo -e "\033[32m  clean all \033[0m"
      break
     ;;
       *)
      echo " 1 or 2"
      continue
esac
done

