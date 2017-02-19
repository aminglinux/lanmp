#!/bin/bash
## writer Shadow-Landon
## e-mail: 972367265@qq.com
## Description : install lamp or lnmp

##咨询用户是否开始运行安装！
echo -e "\033[33m 准备开始安装LAMP/LNMP \033[0m"
echo -e "\033[33m  apache 版本 2.2  2.4 \033[0m"
echo -e "\033[33m  mysql  版本 5.5  5.6 \033[0m"
echo -e "\033[33m  php    版本 5.4  5.6 \033[0m"
echo -e "\033[33m  nginx  版本 1.9 \033[0m" 

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

###设定校验
check_ok(){
    if [ "$?" != 0 ]
     then
          echo -e "\033[31m Oh,no!Please check the error. \033[0m  "
          exit 1
fi
}
##设定回答
check_ack(){
while :
do
if [ $ack == y -o $ack == Y ]
then
   echo -e " OK , continue "
   break
else
    read -p  " Please try again:" ack
    continue
fi
done
}

##定义myum，判断包是否安装，没安装则安装
myum(){
 if ! rpm -qa |grep "^$1"
   then 
      yum -y install $1
      check_ok
  else 
     echo -e "$1 \033[32m 已经安装\033[0m "
fi
  }
##预安装包
echo "检查需要的预安装包"
sleep 2
for p in gcc wget perl perl-devel libaio libaio-devel pcre-devel zlib-devel \
make cmake curl
do
    myum $p
done
sleep 1
##检测网络
echo -e "\033[33m 检查网络 \033[0m "
ping -c 3 mirrors.sohu.com
check_ok

##获取系统是32 还是 64 位

arc=`arch`
##关闭SELINUX
n=`getenforce`
if [ "$n" != 0 ]
     then 
         setenforce 0
fi
##保存并清空IPTABLES
echo -e "iptables 将会被清空并且将原来的规则保存到~/iptables_*"
read -p "确认请输入 [Y]" ack
check_ack
iptables-save > ~/iptables_`date +%F_%T`
check_ok
iptables -F
check_ok
/etc/init.d/iptables save
check_ok
##检查有没有yum源
check_yum(){
   rm -rf /etc/yum.repos.d/*
   wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
    check_ok
    yum clean all
    yum makecache
}
echo  " 检查有没有yum源 "
ls /etc/yum.repos.d/*.repo >/dev/null 2>&1
if [ $? == 0 ]
  then
    echo -e "\033[32m yum源是存在的 \033[0m"
while :
do
   read -p  "请确保yum源可以正常使用，如需覆盖安装：[Y|N]" y
if [ $y == Y -o $y == y ]
then
    check_yum
    break
elif
    [ $y == N -o $y == n ]
then
    echo -e "\033[32m OK continue \033[0m"
    sleep 1
    break
else
    echo  "请输入 Y 或 N "
    continue
fi
done

else
    echo -e "\033[31m yum源不存在,执行安装yum源 \033[0m"
    sleep 2
    check_yum
fi


##添加一个新的epel扩展源，并且将旧的epel源放置到/etc/yum.repos.d/backup
echo "添加一个新的epel扩展源，并且将旧的epel源放置到/etc/yum.repos.d/backup" 
read -p "确认请输入 [Y]" ack
check_ack
if rpm -qa |grep "epel-release"
then 
  rpm -e epel-relese*
fi
if [ ! -d /etc/yum.repos.d/backup ]
then  
   mkdir /etc/yum.repos.d/backup
   check_ok
fi
mv /etc/yum.repos.d/epel* /etc/yum.repos.d/backup  >/dev/null 2>&1
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo 
##mysql 安装过程
mysql_act(){
 if ! grep "^mysql" /etc/passwd
       then
          useradd -M -s /sbin/nologin mysql
          check_ok
      fi
      cd /usr/local/mysql
      [ -f /etc/my.cnf ] && mv /etc/my.cnf /etc/my.cnf`date +%F_%T`
       /bin/cp  support-files/my-huge.cnf /etc/my.cnf
      [ -f /etc/init.d/mysqld ] && mv /etc/init.d/mysqld /etc/init.d/mysqld`date +%F_%T`
       /bin/cp support-files/mysql.server /etc/init.d/mysqld
      [ -d /data/mysql ] && mv /data/mysql /data/mysql`date +%F_%T`
       mkdir -p /data/mysql
       /bin/chown -R mysql /data/mysql
       ./scripts/mysql_install_db --user=mysql --datadir=/data/mysql
       check_ok
       sed -i 's#^basedir=#basedir=/usr/local/mysql#' /etc/init.d/mysqld
       check_ok
       sed -i  's#^datadir=#datadir=/data/mysql#' /etc/init.d/mysqld
       check_ok
       chmod 755 /etc/init.d/mysqld
       chkconfig --add mysqld
       chkconfig mysqld on
       service mysqld start
       check_ok
       break
}
mysql_act2(){
if ! grep "^mysql" /etc/passwd
       then
          useradd -M -s /sbin/nologin mysql
          check_ok
      fi
      cd /usr/local/mysql
      [ -f /etc/my.cnf ] && mv /etc/my.cnf /etc/my.cnf`date +%F_%T`
       /bin/cp  support-files/my-default.cnf  /etc/my.cnf
      [ -f /etc/init.d/mysqld ] && mv /etc/init.d/mysqld /etc/init.d/mysqld`date +%F_%T`
       /bin/cp support-files/mysql.server /etc/init.d/mysqld
      [ -d /data/mysql ] && mv /data/mysql /data/mysql`date +%F_%T`
       mkdir -p /data/mysql
       /bin/chown -R mysql /data/mysql
       ./scripts/mysql_install_db --user=mysql --datadir=/data/mysql
       check_ok
       sed -i 's#^basedir=#basedir=/usr/local/mysql#' /etc/init.d/mysqld
       check_ok
       sed -i  's#^datadir=#datadir=/data/mysql#' /etc/init.d/mysqld
       check_ok
       chmod 755 /etc/init.d/mysqld
       chkconfig --add mysqld
       chkconfig mysqld on
       service mysqld start
       check_ok
       break
}
#安装mysql 5.5 5.6
install_mysqld(){
echo "准备安装 mysql,位置是：/usr/local/mysql  请选择5.5 或 5.6 版本"
select mysql_v in 5.5 5.6
do 
  case $mysql_v in
     5.5)
      cd /usr/local/src
      [ -f mysql-5.5.46-linux2.6-$arc.tar.gz ] || wget http://mirrors.sohu.com/mysql/MySQL-5.5/mysql-5.5.46-linux2.6-$arc.tar.gz 
      tar -zxvf mysql-5.5.46-linux2.6-$arc.tar.gz
       check_ok
      [ -d /usr/local/mysql ]  || mkdir /usr/local/mysql
      mv mysql-5.5.46-linux2.6-$arc/* /usr/local/mysql/
      mysql_act
       ;;
    5.6) 
       cd /usr/local/src
       [ -f mysql-5.6.28-linux-glibc2.5-$arc.tar.gz ] || wget http://mirrors.sohu.com/mysql/MySQL-5.6/mysql-5.6.28-linux-glibc2.5-$arc.tar.gz   
       tar -zxvf mysql-5.6.28-linux-glibc2.5-$arc.tar.gz
       check_ok
       [ -d /usr/local/mysql ]|| mkdir /usr/local/mysql
       mv mysql-5.6.28-linux-glibc2.5-$arc/* /usr/local/mysql  
       mysql_act2
       ;;
      *)
         echo "选择(1)5.5或(2)5.6"
       ;;
esac    
done
}
###安装apache 2.2 或 2.4 版本
install_httpd(){
   echo "准备安装 apache位置是：/usr/local/apache2  请选择2.2 或 2.4 版本"
   select httpd_v in 2.2 2.4
    do
    case $httpd_v in
    2.2) 
    cd /usr/local/src 
    [ -f httpd-2.2.31.tar.gz ] || wget http://mirrors.sohu.com/apache/httpd-2.2.31.tar.gz
    tar -zxvf  httpd-2.2.31.tar.gz
    check_ok
    cd /usr/local/src/httpd-2.2.31
    [ -d /usr/local/apache2 ] && mv /usr/local/apache2 /usr/local/apache2_`date +%F_%T`
    ./configure \
    --prefix=/usr/local/apache2 \
    --with-included-apr \
    --enable-so \
    --enable-deflate=shared \
    --enable-expires=shared \
    --enable-rewrite=shared \
    --with-pcre 
    check_ok
    make && make install
    check_ok
    echo -e "<?php\n    phpinfo();\n?>" > /usr/local/apache2/htdocs/1.php
    [ -f /etc/init.d/httpd ] && /bin/mv /etc/init.d/httpd /etc/init.d/httpd`date +%F_%T`
    /bin/cp /usr/local/apache2/bin/apachectl /etc/init.d/httpd
    sed -i  '/.*bin\/sh/a\#description: Start and stops the Apache HTTP Server.' /usr/local/apache2/bin/apachectl
    check_ok
    sed -i  '/.*bin\/sh/a\#chkconfig:345 85 15' /usr/local/apache2/bin/apachectl    check_ok 
    chmod 755 /etc/init.d/httpd 
    check_ok
    chkconfig --add httpd
    /etc/init.d/httpd start
     check_ok
    echo -e "\033[32m apache OK \033[0m"
    check_ok
    sleep 1
    break
    ;;
  
     2.4)
    cd /usr/local/src
    [ -f httpd-2.4.17.tar.gz ] || wget http://mirrors.sohu.com/apache/httpd-2.4.17.tar.gz
    tar -zxvf  httpd-2.4.17.tar.gz
    check_ok
    wget http://mirrors.cnnic.cn/apache/apr/apr-1.5.2.tar.bz2
    tar -jxvf apr-1.5.2.tar.bz2
    check_ok
     wget http://mirrors.cnnic.cn/apache/apr/apr-util-1.5.4.tar.gz
    tar -zxvf apr-util-1.5.4.tar.gz
    check_ok
    cd /usr/local/src/apr-1.5.2
    ./configure --prefix=/usr/local/apr
    make && make install
    cd /usr/local/src/apr-util-1.5.4
    ./configure --prefix=/usr/local/apr-util  --with-apr=/usr/local/apr/
    make && make install
    [ -d /usr/local/apache2 ] && mv /usr/local/apache2 /usr/local/apache2_`date +%F_%T`
    cd /usr/local/src/httpd-2.4.17
    ./configure \
    --prefix=/usr/local/apache2 \
    --with-apr=/usr/local/apr \
    --with-apr-util=/usr/local/apr-util \
    --enable-so \
    --enable-deflate=shared \
    --enable-expires=shared \
    --enable-rewrite=shared \
    --with-pcre \
    --with-mpm=worker
    check_ok
     make && make install
     check_ok
    echo -e "<?php\n    phpinfo();\n?>" > /usr/local/apache2/htdocs/1.php
      [ -f /etc/init.d/httpd ] && /bin/mv /etc/init.d/httpd /etc/init.d/httpd`date +%F_%T`
    /bin/cp /usr/local/apache2/bin/apachectl /etc/init.d/httpd
    sed -i  '/.*bin\/sh/a\#description: Start and stops the Apache HTTP Server.' /usr/local/apache2/bin/apachectl
    check_ok
    sed -i  '/.*bin\/sh/a\#chkconfig:345 85 15' /usr/local/apache2/bin/apachectl    check_ok
    chmod 755 /etc/init.d/httpd
    check_ok
    chkconfig --add httpd
    /etc/init.d/httpd start
     check_ok
     echo -e "\033[32m apache OK \033[0m"
     check_ok
     sleep 1
     break
     ;;
    *)
     echo "选择 (1) 2.2 或 (2) 2.4"
     continue
esac
done
}

##php的安装5.4 5.6
install_php(){
    echo "准备安装php 位置是:/usr/local/php，选择版本 5.4 或 5.6 "
  select php_v in 5.4 5.6
  do
   case $php_v in
    5.4)
       cd /usr/local/src
       [ -f php-5.4.40.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.4.40.tar.gz  
       tar -zxvf php-5.4.40.tar.gz
       check_ok
       cd php-5.4.40
       for pkg in  libtool libtool-ltdl-devel  libxml2-devel   bzip2 bzip2-devel libpng libpng-devel  freetype freetype-devel   libmcrypt-devel   openssl-devel  libjpeg-turbo-devel
       do 
           myum $pkg
       done
       ./configure  --prefix=/usr/local/php  --with-apxs2=/usr/local/apache2/bin/apxs --with-config-file-path=/usr/local/php/etc   --with-mysql=mysqlnd  --with-mysqli=mysqlnd  --with-pdo-mysql=mysqlnd --with-libxml-dir --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-zlib-dir --with-bz2 --with-openssl --with-mcrypt  --enable-soap  --enable-gd-native-ttf  --enable-mbstring  --enable-sockets  --enable-exif  --disable-ipv6 --disable-fileinfo
        check_ok
        make && make install
        check_ok
        /bin/cp php.ini-production /usr/local/php/etc/php.ini
        break
        ;;
      5.6)
      cd /usr/local/src
       [ -f php-5.6.0.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.6.0.tar.gz    
       tar -zxvf php-5.6.0.tar.gz
       cd php-5.6.0
        for pkg in  libxml2-devel   bzip2 bzip2-devel libpng libpng-devel  freetype freetype-devel   libmcrypt-devel   openssl-devel    libjpeg-turbo-devel  libtool  libtool-ltdl-devel      
         do
           myum $pkg
       done
       ./configure  --prefix=/usr/local/php  --with-apxs2=/usr/local/apache2/bin/apxs --with-config-file-path=/usr/local/php/etc   --with-mysql=mysqlnd  --with-mysqli=mysqlnd  --with-pdo-mysql=mysqlnd --with-libxml-dir --with-gd --with-jpeg-dir --with-png-dir --with-freetype-dir --with-iconv-dir --with-zlib-dir --with-bz2 --with-openssl --with-mcrypt  --enable-soap  --enable-gd-native-ttf  --enable-mbstring  --enable-sockets  --enable-exif  --disable-ipv6 --disable-fileinfo
        check_ok
        make && make install
        check_ok
        /bin/cp php.ini-production /usr/local/php/etc/php.ini
        break
        ;;
       *)
        echo "选择 (1) 5.4 或 (2) 5.6"
esac
done
}
##apache 和 php 的结合

httpd_php(){
        sed -i '/AddType .*.gz .tgz$/a\AddType application\/x-httpd-php .php' /usr/local/apache2/conf/httpd.conf
check_ok
       sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/' /usr/local/apache2/conf/httpd.conf
check_ok
       sed -i 's/#ServerName www.example.com:80/ServerName www.example.com:80/' /usr/local/apache2/conf/httpd.conf 
       sed -i 's/Deny/Allow/' /usr/local/apache2/conf/httpd.conf
cat > /usr/local/apache2/htdocs/index.php <<EOF
<?php
   phpinfo();
?>
EOF

if /usr/local/php/bin/php -i |grep -iq 'date.timezone => no value'
then
    sed -i '/;date.timezone =$/a\date.timezone = Asia\/Chongqing'  /usr/local/php/etc/php.ini
fi

/usr/local/apache2/bin/apachectl restart
check_ok
}      
  
httpd_php_2(){
       sed -i 's/#ServerName www.example.com:80/ServerName www.example.com:80/' /usr/local/apache2/conf/httpd.conf
       sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html index.htm/' /usr/local/apache2/conf/httpd.conf
        sed -i '/AddType .*.gz .tgz$/a\AddType application\/x-httpd-php .php' /usr/local/apache2/conf/httpd.conf
       sed -i 's/denied/granted/' /usr/local/apache2/conf/httpd.conf
cat > /usr/local/apache2/htdocs/index.php <<EOF
<?php
   phpinfo();
?>
EOF

if /usr/local/php/bin/php -i |grep -iq 'date.timezone => no value'
then
    sed -i '/;date.timezone =$/a\date.timezone = Asia\/Chongqing'  /usr/local/php/etc/php.ini
fi

/usr/local/apache2/bin/apachectl restart
check_ok
echo "\033[32m apache restart...ok \033[0m"
}
#检查服务是否存在
check_srv(){
if [ "$1" == "phpfpm" ]
then
    s="php-fpm"
else
    s=$1
fi
n=`ps aux |grep "$s"|wc -l`
if [ $n -gt 1 ]
then
    echo -e "$s \033[32m 已经启动。\033[0m"
else
    if [ -f /etc/init.d/$s ]
    then
        /etc/init.d/$s start
        check_ok
    else
        install_$1
    fi
fi
}

##安装nginx
install_nginx(){
     echo "正在安装nginx"
    sleep 2
     cd /usr/local/src 
     [ -f nginx-1.9.0.tar.gz ] || wget http://mirrors.sohu.com/nginx/nginx-1.9.0.tar.gz
      tar -zxvf nginx-1.9.0.tar.gz
      cd nginx-1.9.0
      ./configure   --prefix=/usr/local/nginx   --with-pcre 
      make 
      make install
      if [ -f /etc/init.d/nginx ]
then
    /bin/mv /etc/init.d/nginx  /etc/init.d/nginx_`date +%F_%T`
fi     
      /usr/bin/curl http://www.apelearn.com/study_v2/.nginx_init  -o /etc/init.d/nginx
      check_ok
      chmod 755 /etc/init.d/nginx
      chkconfig --add nginx
      chkconfig nginx on
      curl http://www.apelearn.com/study_v2/.nginx_conf -o /usr/local/nginx/conf/nginx.conf
       check_ok
      echo -e "<?php\n  phpinfo();\n?>" > /usr/local/nginx/html/1.php
       service nginx start
       check_ok
       echo -e "\033[32m nginx 已启动 \033[0m"
       sleep 2
}

##安装php-fpm
php_act(){
       /usr/sbin/useradd -s /sbin/nologin -M php-fpm
         for pkg in  libxml2-devel   bzip2 bzip2-devel libpng libpng-devel  freetype freetype-devel   libmcrypt-devel   openssl-devel    libjpeg-turbo-devel  libtool  libtool-ltdl-devel libcurl-devel libcurl
         do
           myum $pkg
       done
       ./configure --prefix=/usr/local/php-fpm   --with-config-file-path=/usr/local/php-fpm/etc  --enable-fpm   --with-fpm-user=php-fpm  --with-fpm-group=php-fpm  --with-mysql=/usr/local/mysql  --with-mysql-sock=/tmp/mysql.sock  --with-libxml-dir  --with-gd   --with-jpeg-dir   --with-png-dir   --with-freetype-dir  --with-iconv-dir   --with-zlib-dir   --with-mcrypt   --enable-soap   --enable-gd-native-ttf   --enable-ftp  --enable-mbstring  --enable-exif    --disable-ipv6     --with-curl   --with-openssl --disable-fileinfo
       check_ok
        make && make install
       check_ok
       [ -f /usr/local/php-fpm/etc/php.ini ] && rm -rf /usr/local/php-fpm/etc/php.ini &&  /bin/cp php.ini-production /usr/local/php-fpm/etc/php.ini || /bin/cp php.ini-production /usr/local/php-fpm/etc/php.ini
       if /usr/local/php-fpm/bin/php -i |grep -iq 'date.timezone => no value'
            then
                sed -i '/;date.timezone =$/a\date.timezone = "Asia\/Chongqing"'  /usr/local/php-fpm/etc/php.ini
                check_ok
            fi
       /bin/mv  /usr/local/php-fpm/etc/php-fpm.conf.default  /usr/local/php-fpm/etc/php-fpm.conf
cat > /usr/local/php-fpm/etc/php-fpm.conf << EOF
[global]
pid = /usr/local/php-fpm/var/run/php-fpm.pid
error_log = /usr/local/php-fpm/var/log/php-fpm.log
[www]
listen = /tmp/php-fcgi.sock
user = php-fpm
group = php-fpm
listen.mode = 0666
pm = dynamic
pm.max_children = 50
pm.start_servers = 20
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
rlimit_files = 1024
EOF
      [ -f /etc/init.d/php-fpm ] || /bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
            chmod 755 /etc/init.d/php-fpm
            chkconfig php-fpm on
            service php-fpm start
            check_ok
}

install_phpfpm(){
        echo "请选择php版本 5.4  或 5.6 "
        select php_v in 5.4 5.6
          do
         case $php_v in 
         5.4)  
         cd /usr/local/src
        [ -f php-5.4.40.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.4.40.tar.gz
        tar -zxvf php-5.4.40.tar.gz
        check_ok
          cd php-5.4.40
          php_act
          break
          ;;
         5.6)
          cd /usr/local/src/
            [ -f php-5.6.6.tar.gz ] || wget http://mirrors.sohu.com/php/php-5.6.6.tar.gz       
         tar -zxvf php-5.6.6.tar.gz
        check_ok
         cd php-5.6.6
         php_act
         break
          ;;
          *)
          echo "1 或者 2"
          continue
esac
done
}

##验证php是否成功解析
check_php(){
echo " 测试php是否成功解析"
sleep 2
curl -I 127.0.0.1/1.php|grep PHP >/dev/null 2>&1

if [ $? == 0 ]
then
  echo "恭喜，已成功解析PHP"
else
  echo "遗憾，没能成功解析PHP"
fi
}
##LAMP
lamp(){
    check_srv mysqld
    check_srv httpd
    install_php
    if /usr/local/apache2/bin/apachectl -v|grep -iq "Apache/2.4.17"
     then
         httpd_php_2
    else
      httpd_php
    fi
    echo -e "\033[32m Install Finished!\033[0m"
    /etc/init.d/httpd restart
    check_php
}
##LNMP
lnmp(){
      check_srv mysqld
      check_srv nginx
      check_srv phpfpm
      echo -e "\033[32m Install Finsh \033[0m"
      /etc/init.d/nginx restart
       check_php
}
echo "预装环境已准备完毕，准备安装LAMP 或 LNMP"
select l in lamp lnmp
   do 
   case $l in 
       lamp)
          lamp
          break
       ;;
      lnmp)
          lnmp
          break
        ;;
       *)
         echo " (1) lanmp (2) lnmp"
         continue
esac
done
      
